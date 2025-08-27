<?php
date_default_timezone_set('Asia/Jakarta');
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

$out = ['success'=>false,'message'=>'','data'=>null];
$mysqli = @new mysqli('localhost','root','','dpr_bites');
if ($mysqli->connect_errno) { $out['message']='DB connection failed'; echo json_encode($out); exit; }
$mysqli->set_charset('utf8mb4');

$raw = file_get_contents('php://input');
$payload = json_decode($raw,true);
if (!is_array($payload)) $payload = $_POST;

$userId  = isset($payload['user_id']) ? (int)$payload['user_id'] : 0;
$geraiId = isset($payload['gerai_id']) ? (int)$payload['gerai_id'] : 0;
$menuId  = isset($payload['menu_id']) ? (int)$payload['menu_id'] : 0;
$qtyProvided = array_key_exists('qty',$payload);
$qty     = $qtyProvided ? (int)$payload['qty'] : null; // null means auto for new insert
$addons  = isset($payload['addons']) && is_array($payload['addons']) ? array_map('intval',$payload['addons']) : [];
// Flag whether client explicitly sent addons (to allow retaining existing when empty)
$addonsExplicit = array_key_exists('addons',$payload);
$noteProvided = array_key_exists('note',$payload);
$note = $noteProvided ? trim((string)$payload['note']) : null; // optional per-item note

if ($userId<=0 || $geraiId<=0 || $menuId<=0) { $out['message']='Missing required ids'; echo json_encode($out); exit; }

// Validate gerai & menu
$stmt = $mysqli->prepare("SELECT m.id_menu, m.harga, m.id_gerai FROM menu m WHERE m.id_menu=? LIMIT 1");
$stmt->bind_param('i',$menuId);
$stmt->execute();
$res = $stmt->get_result();
if (!$res || $res->num_rows===0) { $out['message']='Menu not found'; echo json_encode($out); exit; }
$menuRow = $res->fetch_assoc();
$stmt->close();
if ((int)$menuRow['id_gerai'] !== $geraiId) { $out['message']='Menu not in gerai'; echo json_encode($out); exit; }
$basePrice = (int)$menuRow['harga'];

// Determine if menu has addon choices
$hasAddon = false; $allowedAddonIds = [];
$q = $mysqli->prepare("SELECT ma.id_addon FROM menu_addon ma JOIN addon a ON a.id_addon=ma.id_addon WHERE ma.id_menu=?");
$q->bind_param('i',$menuId);
$q->execute();
$rq = $q->get_result();
while ($rw = $rq->fetch_assoc()) { $hasAddon = true; $allowedAddonIds[] = (int)$rw['id_addon']; }
$q->close();

// Filter addons to allowed
if ($hasAddon) {
  $addons = array_values(array_intersect($addons,$allowedAddonIds));
} else {
  $addons = []; // ignore provided
}

// Auto qty if new & not provided and no addon selection step (menu without addons)
$autoQtyDefault = 1;

$mysqli->begin_transaction();
try {
    // Find existing keranjang (cart) with status aktif for this user & gerai
    $cartId = null;
    $stmt = $mysqli->prepare("SELECT id_keranjang FROM keranjang WHERE id_users=? AND id_gerai=? AND status='aktif' ORDER BY id_keranjang DESC LIMIT 1");
    $stmt->bind_param('ii',$userId,$geraiId);
    $stmt->execute();
    $rs = $stmt->get_result();
    if ($rs && $rs->num_rows>0) { $cartId = (int)$rs->fetch_assoc()['id_keranjang']; }
    $stmt->close();

    if ($cartId===null) {
        $stmt = $mysqli->prepare("INSERT INTO keranjang (id_users,id_gerai,status,total_harga,total_qty) VALUES (?,?,?,?,?)");
        $zero = 0; $status='aktif'; $totalQty=0;
        $stmt->bind_param('iisii',$userId,$geraiId,$status,$zero,$totalQty);
        $stmt->execute();
        $cartId = $stmt->insert_id; $stmt->close();
    }

    // Check existing item (single variant only for now: first match). If you want per-addon variant rows, adjust query logic.
    $itemId = null; $oldQty = 0; $existingAddonIds=[];
    $stmt = $mysqli->prepare("SELECT id_keranjang_item,qty,note FROM keranjang_item WHERE id_keranjang=? AND id_menu=? LIMIT 1");
    $stmt->bind_param('ii',$cartId,$menuId);
    $stmt->execute(); $ri=$stmt->get_result();
    if ($ri && $ri->num_rows>0) { $rowi=$ri->fetch_assoc(); $itemId=(int)$rowi['id_keranjang_item']; $oldQty=(int)$rowi['qty']; }
    $stmt->close();
    if ($itemId!==null) {
        $ga=$mysqli->prepare("SELECT id_addon FROM keranjang_item_addon WHERE id_keranjang_item=?");
        $ga->bind_param('i',$itemId); $ga->execute(); $ra=$ga->get_result();
        while ($ra && $ar=$ra->fetch_assoc()) { $existingAddonIds[]=(int)$ar['id_addon']; }
        $ga->close();
    }

    // Determine target qty
    if ($itemId===null) {
        if ($qty===null) { $qty=$autoQtyDefault; }
    } else {
        if ($qty===null) { $qty=$oldQty; }
    }

    if ($qty<0) $qty=0;

    // If updating existing and addons not explicitly sent (parameter absent), retain previous addons.
    // NOTE: If client explicitly sends an empty array, we interpret that as clearing all addons.
    if ($itemId!==null && $hasAddon && (!$addonsExplicit)) {
        $addons = $existingAddonIds; // keep existing because client didn't specify
    }
    $itemDeleted = false;
    if ($qty===0 && $itemId!==null) {
        // Delete addons then item
        $d = $mysqli->prepare("DELETE FROM keranjang_item_addon WHERE id_keranjang_item=?");
        $d->bind_param('i',$itemId); $d->execute(); $d->close();
        $d = $mysqli->prepare("DELETE FROM keranjang_item WHERE id_keranjang_item=?");
        $d->bind_param('i',$itemId); $d->execute(); $d->close();
        $itemId = null;
        $itemDeleted = true;
    } elseif ($qty>0) {
        // Compute addon single-unit price addition
        $addonUnitAdd = 0;
        if (!empty($addons)) {
            // Sum addon prices
            if (!empty($addons)) {
                $in = implode(',',array_fill(0,count($addons),'?'));
                $types = str_repeat('i',count($addons));
                $sqlAdd = "SELECT harga FROM addon WHERE id_addon IN ($in)";
                $st = $mysqli->prepare($sqlAdd);
                $st->bind_param($types,...$addons);
                $st->execute();
                $rsAdd = $st->get_result();
                while ($ra=$rsAdd->fetch_assoc()) { $addonUnitAdd += (int)$ra['harga']; }
                $st->close();
            }
        }
        $unitPrice = $basePrice + $addonUnitAdd; // harga per item termasuk addon
        $subtotal = $unitPrice * $qty;
        if ($itemId===null) {
            // Insert new with note (column 'note' must exist in keranjang_item)
            $ins = $mysqli->prepare("INSERT INTO keranjang_item (id_keranjang,id_menu,qty,harga_satuan,subtotal,note) VALUES (?,?,?,?,?,?)");
            $noteForInsert = $noteProvided ? $note : null; // if not provided keep NULL
            $ins->bind_param('iiiiis',$cartId,$menuId,$qty,$unitPrice,$subtotal,$noteForInsert);
            $ins->execute();
            $itemId = $ins->insert_id; $ins->close();
        } else {
            if ($noteProvided) {
                $upd = $mysqli->prepare("UPDATE keranjang_item SET qty=?, harga_satuan=?, subtotal=?, note=? WHERE id_keranjang_item=?");
                // Correct type order: int,int,int,string,int
                $upd->bind_param('iiisi',$qty,$unitPrice,$subtotal,$note,$itemId);
            } else {
                $upd = $mysqli->prepare("UPDATE keranjang_item SET qty=?, harga_satuan=?, subtotal=? WHERE id_keranjang_item=?");
                $upd->bind_param('iiii',$qty,$unitPrice,$subtotal,$itemId);
            }
            $upd->execute(); $upd->close();
            // Clear existing addons for this item (will reinsert)
            $clr = $mysqli->prepare("DELETE FROM keranjang_item_addon WHERE id_keranjang_item=?");
            $clr->bind_param('i',$itemId); $clr->execute(); $clr->close();
        }
        // Insert addons rows
        if ($itemId!==null && !empty($addons)) {
            $insA = $mysqli->prepare("INSERT INTO keranjang_item_addon (id_keranjang_item,id_addon) VALUES (?,?)");
            foreach ($addons as $ad) { $insA->bind_param('ii',$itemId,$ad); $insA->execute(); }
            $insA->close();
        }
    }

    // Recalculate total_harga & total_qty in keranjang
    $sum = 0; $totalQty=0;
    $rsum = $mysqli->prepare("SELECT qty, subtotal FROM keranjang_item WHERE id_keranjang=?");
    $rsum->bind_param('i',$cartId);
    $rsum->execute();
    $gres = $rsum->get_result();
    while ($gr = $gres->fetch_assoc()) { $sum += (int)$gr['subtotal']; $totalQty += (int)$gr['qty']; }
    $rsum->close();
    $upT = $mysqli->prepare("UPDATE keranjang SET total_harga=?, total_qty=? WHERE id_keranjang=?");
    $upT->bind_param('iii',$sum,$totalQty,$cartId);
    $upT->execute(); $upT->close();

    $mysqli->commit();

    // Build item detail output (current item if exists)
    $itemData = null; $itemAddons=[];
    if ($itemId!==null) {
        $g = $mysqli->prepare("SELECT id_keranjang_item,qty,harga_satuan,subtotal,note FROM keranjang_item WHERE id_keranjang_item=? LIMIT 1");
        $g->bind_param('i',$itemId); $g->execute(); $gi=$g->get_result();
        if ($gi && $gi->num_rows>0) { $row=$gi->fetch_assoc(); $itemData = [
            'id_keranjang_item'=>(int)$row['id_keranjang_item'],
            'menu_id'=>$menuId,
            'qty'=>(int)$row['qty'],
            'harga_satuan'=>(int)$row['harga_satuan'],
            'subtotal'=>(int)$row['subtotal'],
            'note'=>$row['note'],
        ]; }
        $g->close();
        if ($itemData) {
            $ga = $mysqli->prepare("SELECT id_addon FROM keranjang_item_addon WHERE id_keranjang_item=?");
            $ga->bind_param('i',$itemId); $ga->execute(); $ra=$ga->get_result();
            while ($raRow=$ra->fetch_assoc()) { $itemAddons[] = (int)$raRow['id_addon']; }
            $ga->close();
            $itemData['addons'] = $itemAddons;
        }
    }

    $out['success']=true;
    $out['data']=[
        'keranjang_id'=>$cartId,
        'total_qty'=>$totalQty,
        'total_harga'=>$sum,
        'item'=>$itemData,
        'deleted'=>$itemDeleted,
        'menu_id'=>$menuId
    ];
} catch (Throwable $e) {
    $mysqli->rollback();
    $out['message']='Error: '.$e->getMessage();
}

echo json_encode($out);
