<?php
date_default_timezone_set('Asia/Jakarta');
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

$out = ['success'=>false,'message'=>'','data'=>null];
$mysqli = @new mysqli('localhost','root','','dpr_bites');
if ($mysqli->connect_errno) { $out['message']='DB connection failed'; echo json_encode($out); exit; }
$mysqli->set_charset('utf8mb4');

$userId  = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$geraiId = isset($_GET['gerai_id']) ? (int)$_GET['gerai_id'] : 0;
if ($userId<=0 || $geraiId<=0) { $out['message']='Missing ids'; echo json_encode($out); exit; }

// Find active cart
$cartId = null; $stmt = $mysqli->prepare("SELECT id_keranjang,total_harga,total_qty FROM keranjang WHERE id_users=? AND id_gerai=? AND status='aktif' ORDER BY id_keranjang DESC LIMIT 1");
$stmt->bind_param('ii',$userId,$geraiId); $stmt->execute(); $rs=$stmt->get_result(); $totHarga=0; $totQty=0;
if ($rs && $rs->num_rows>0) { $row=$rs->fetch_assoc(); $cartId=(int)$row['id_keranjang']; $totHarga=(int)$row['total_harga']; $totQty=(int)$row['total_qty']; }
$stmt->close();
if ($cartId===null) { $out['success']=true; $out['data']=['keranjang_id'=>null,'total_qty'=>0,'total_harga'=>0,'items'=>[]]; echo json_encode($out); exit; }

$items=[]; $st = $mysqli->prepare("SELECT id_keranjang_item,id_menu,qty,harga_satuan,subtotal FROM keranjang_item WHERE id_keranjang=?");
$st->bind_param('i',$cartId); $st->execute(); $ri=$st->get_result();
while ($ri && $row=$ri->fetch_assoc()) {
  $iid=(int)$row['id_keranjang_item'];
  $addonIds=[]; $ga=$mysqli->prepare("SELECT id_addon FROM keranjang_item_addon WHERE id_keranjang_item=? ORDER BY id_addon ASC");
  $ga->bind_param('i',$iid); $ga->execute(); $ra=$ga->get_result();
  while ($ra && $ar=$ra->fetch_assoc()) { $addonIds[]=(int)$ar['id_addon']; }
  $ga->close();
  $items[]=[
    'id_keranjang_item'=>$iid,
    'menu_id'=>(int)$row['id_menu'],
    'qty'=>(int)$row['qty'],
    'harga_satuan'=>(int)$row['harga_satuan'],
    'subtotal'=>(int)$row['subtotal'],
    'addons'=>$addonIds,
  ];
}
$st->close();

// Recalculate totals defensively if mismatch
$calcTotQty=0; $calcTotHarga=0; foreach($items as $it){ $calcTotQty+=$it['qty']; $calcTotHarga+=$it['subtotal']; }
if ($calcTotQty!=$totQty || $calcTotHarga!=$totHarga) {
  $totQty=$calcTotQty; $totHarga=$calcTotHarga;
  $u=$mysqli->prepare("UPDATE keranjang SET total_harga=?, total_qty=? WHERE id_keranjang=?");
  $u->bind_param('iii',$totHarga,$totQty,$cartId); $u->execute(); $u->close();
}

$out['success']=true; $out['data']=[
  'keranjang_id'=>$cartId,
  'total_qty'=>$totQty,
  'total_harga'=>$totHarga,
  'items'=>$items
];
echo json_encode($out);