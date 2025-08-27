<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Accept');

// Matikan tampilan warning/notice agar tidak merusak JSON
@ini_set('display_errors', 0);
error_reporting(E_ERROR | E_PARSE);

// Koneksi langsung sesuai permintaan (ubah credential jika perlu)
$conn = @new mysqli('localhost','root','','dpr_bites');
if ($conn->connect_errno) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'DB connection failed: '.$conn->connect_error,
        'data' => null,
    ]);
    exit;
}

function respond($ok, $message = '', $data = null, $code = 200) {
    http_response_code($code);
    echo json_encode([
        'success' => $ok,
        'message' => $message,
        'data' => $data,
    ]);
    exit;
}

$raw = file_get_contents('php://input');
$input = [];
if ($raw) {
    $decoded = json_decode($raw, true);
    if (is_array($decoded)) $input = $decoded;
}
// allow GET fallback
if (isset($_GET['user_id'])) $input['user_id'] = $_GET['user_id'];
if (isset($_GET['gerai_id'])) $input['gerai_id'] = $_GET['gerai_id'];

$userId = isset($input['user_id']) ? (int)$input['user_id'] : 0;
$geraiId = isset($input['gerai_id']) ? (int)$input['gerai_id'] : 0;
if ($userId <= 0 || $geraiId <= 0) {
    respond(false, 'Missing user_id or gerai_id', null, 400);
}

// 1. Ambil keranjang aktif
$sqlCart = "SELECT id_keranjang, total_harga, total_qty FROM keranjang WHERE id_users=? AND id_gerai=? AND status='aktif' ORDER BY updated_at DESC LIMIT 1";
$stmt = $conn->prepare($sqlCart);
$stmt->bind_param('ii', $userId, $geraiId);
$stmt->execute();
$resCart = $stmt->get_result();
if ($resCart->num_rows === 0) {
    respond(true, 'Empty cart', [
        'restaurantName' => '',
        'deliveryFee' => 0,
        'items' => [],
        'address' => null,
    ]);
}
$cartRow = $resCart->fetch_assoc();
$cartId = (int)$cartRow['id_keranjang'];

// 2. Ambil nama gerai
$sqlGerai = "SELECT nama_gerai, detail_alamat, qris_path FROM gerai WHERE id_gerai=? LIMIT 1";
$stmt = $conn->prepare($sqlGerai);
$stmt->bind_param('i', $geraiId);
$stmt->execute();
$resGerai = $stmt->get_result();
$geraiName = '';
$geraiAlamat = '';
$qrisPath = null;
if ($resGerai->num_rows > 0) {
    $g = $resGerai->fetch_assoc();
    $geraiName = $g['nama_gerai'];
    $geraiAlamat = $g['detail_alamat'];
    $qrisPath = $g['qris_path'];
}

// 3. Ambil items
$sqlItems = "SELECT ki.id_keranjang_item, ki.id_menu, ki.qty, ki.harga_satuan, ki.subtotal, ki.note, m.nama_menu, m.gambar_menu, m.deskripsi_menu FROM keranjang_item ki JOIN menu m ON m.id_menu=ki.id_menu WHERE ki.id_keranjang=?";
$stmt = $conn->prepare($sqlItems);
$stmt->bind_param('i', $cartId);
$stmt->execute();
$resItems = $stmt->get_result();
$items = [];
$itemIds = [];
while ($row = $resItems->fetch_assoc()) {
    $iid = (int)$row['id_keranjang_item'];
    $itemIds[] = $iid;
    $items[$iid] = [
        'cartItemId' => $iid,
        'menuId' => (int)$row['id_menu'],
        'name' => $row['nama_menu'],
        'image' => $row['gambar_menu'],
        'desc' => $row['deskripsi_menu'],
        'price' => (int)$row['harga_satuan'],
        'qty' => (int)$row['qty'],
        'subtotal' => (int)$row['subtotal'],
        'note' => $row['note'],
        'addonOptions' => [], // will fill
        'addon' => [], // selected labels
    ];
}

// 4. Ambil addon utk item (jika ada)
if (!empty($itemIds)) {
    $in = implode(',', array_fill(0, count($itemIds), '?'));
    $types = str_repeat('i', count($itemIds));
    $sqlAddons = "SELECT kia.id_keranjang_item, a.id_addon, a.nama_addon, a.harga, a.image_path FROM keranjang_item_addon kia JOIN addon a ON a.id_addon = kia.id_addon WHERE kia.id_keranjang_item IN ($in)";
    $stmt = $conn->prepare($sqlAddons);
    $stmt->bind_param($types, ...$itemIds);
    $stmt->execute();
    $resAdd = $stmt->get_result();
    while ($row = $resAdd->fetch_assoc()) {
        $iid = (int)$row['id_keranjang_item'];
        if (!isset($items[$iid])) continue;
        $items[$iid]['addon'][] = $row['nama_addon'];
        $items[$iid]['addonOptions'][] = [
            'id' => (int)$row['id_addon'],
            'label' => $row['nama_addon'],
            'price' => (int)$row['harga'],
            'image' => $row['image_path'],
        ];
    }
}

// 5. Alamat utama user (optional)
$sqlAlamat = "SELECT nama_penerima, nama_gedung, detail_pengantaran, no_hp FROM alamat_pengantaran WHERE id_users=? AND alamat_utama=1 LIMIT 1";
$stmt = $conn->prepare($sqlAlamat);
$stmt->bind_param('i', $userId);
$stmt->execute();
$resAlamat = $stmt->get_result();
$alamat = null;
if ($resAlamat->num_rows > 0) {
    $a = $resAlamat->fetch_assoc();
    $alamat = [
        'nama_penerima' => $a['nama_penerima'],
        'nama_gedung' => $a['nama_gedung'],
        'detail_pengantaran' => $a['detail_pengantaran'],
        'no_hp' => $a['no_hp'],
    ];
}

// 6. Build response list preserving original array order
$itemsList = array_values($items);

respond(true, 'OK', [
    'restaurantName' => $geraiName,
    'restaurantAddress' => $geraiAlamat,
    'qrisPath' => $qrisPath,
    'deliveryFee' => 5000, // static or compute later
    'items' => $itemsList,
    'address' => $alamat,
]);
?>