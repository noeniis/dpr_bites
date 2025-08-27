<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$response = ['success' => false, 'data' => null, 'message' => ''];

$mysqli = @new mysqli('localhost', 'root', '', 'dpr_bites');
if ($mysqli->connect_errno) {
    $response['message'] = 'DB connection failed';
    echo json_encode($response); exit;
}
$mysqli->set_charset('utf8mb4');

$id = isset($_GET['id']) ? trim($_GET['id']) : '';
if ($id === '') {
    $response['message'] = 'Missing id';
    echo json_encode($response); exit;
}

// Detect optional columns
$menuColumns = [];
if ($resCols = $mysqli->query("SHOW COLUMNS FROM menu")) {
    while ($r = $resCols->fetch_assoc()) { $menuColumns[$r['Field']] = true; }
    $resCols->free();
}
$addonColumns = [];
if ($resACols = $mysqli->query("SHOW COLUMNS FROM addon")) {
    while ($r = $resACols->fetch_assoc()) { $addonColumns[$r['Field']] = true; }
    $resACols->free();
}

// Build SELECT with correct PK id_menu
$selectMenu = [];
$selectMenu[] = 'm.id_menu AS id';
$selectMenu[] = ($menuColumns['nama_menu'] ?? false) ? 'm.nama_menu' : "'' AS nama_menu";
$selectMenu[] = ($menuColumns['deskripsi_menu'] ?? false) ? 'm.deskripsi_menu' : "'' AS deskripsi_menu";
$selectMenu[] = ($menuColumns['harga'] ?? false) ? 'm.harga' : '0 AS harga';
$selectMenu[] = ($menuColumns['gambar_menu'] ?? false) ? 'm.gambar_menu' : "'' AS gambar_menu";

$sql = 'SELECT '.implode(',', $selectMenu).' FROM menu m WHERE m.id_menu = ? LIMIT 1';
$stmt = $mysqli->prepare($sql);
if (!$stmt) {
    $response['message'] = 'Prepare failed';
    echo json_encode($response); exit;
}
$stmt->bind_param('s', $id);
$stmt->execute();
$menuRes = $stmt->get_result();
if (!$menuRes || $menuRes->num_rows === 0) {
    $response['message'] = 'Menu not found';
    echo json_encode($response); exit;
}
$menuRow = $menuRes->fetch_assoc();
$stmt->close();

// Fetch addons for this menu, assume relation table menu_addon(menu_id, addon_id) or addon has menu_id
// We'll check both possibilities dynamically.
// Fetch addons via pivot menu_addon (schema: menu_addon.id_menu, menu_addon.id_addon)
$addons = [];
if ($checkMAT = $mysqli->query("SHOW TABLES LIKE 'menu_addon'")) {
    if ($checkMAT->num_rows > 0) {
        $addonSelect = [];
        $addonSelect[] = 'a.id_addon AS id';
        $addonSelect[] = ($addonColumns['nama_addon'] ?? false) ? 'a.nama_addon' : "'' AS nama_addon";
        $addonSelect[] = ($addonColumns['harga'] ?? false) ? 'a.harga' : '0 AS harga';
        $addonSelect[] = ($addonColumns['image_path'] ?? false) ? 'a.image_path' : "'' AS image_path";
        $sqlAddon = 'SELECT '.implode(',', $addonSelect).' FROM addon a JOIN menu_addon ma ON ma.id_addon = a.id_addon WHERE ma.id_menu = ?';
        if ($stA = $mysqli->prepare($sqlAddon)) {
            $stA->bind_param('s', $id);
            $stA->execute();
            if ($resA = $stA->get_result()) {
                while ($rowA = $resA->fetch_assoc()) {
                    $addons[] = [
                        'id' => $rowA['id'],
                        'label' => $rowA['nama_addon'] ?? '',
                        'price' => (int)($rowA['harga'] ?? 0),
                        'image' => $rowA['image_path'] ?? ''
                    ];
                }
            }
            $stA->close();
        }
    }
    $checkMAT->free();
}

$menuData = [
    'id' => $menuRow['id'],
    'nama_menu' => $menuRow['nama_menu'] ?? '',
    'deskripsi_menu' => $menuRow['deskripsi_menu'] ?? '',
    'harga' => (int)($menuRow['harga'] ?? 0),
    'gambar_menu' => $menuRow['gambar_menu'] ?? '',
    'addonOptions' => $addons,
];

$response['success'] = true;
$response['data'] = $menuData;

echo json_encode($response);
