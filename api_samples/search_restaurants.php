<?php
// Hardening: cegah warning/notice muncul ke output JSON
error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING & ~E_DEPRECATED & ~E_STRICT);
ini_set('display_errors', 0);
ob_start();
// search_restaurants.php
// Parameter: q (query string)
// Mencari restoran (gerai) dengan status_pengajuan = 'approved' yang nama/desc cocok
// atau memiliki menu yang namanya mengandung query. Mengembalikan struktur:
// success, data: [ { id, name, profilePic, rating, ratingCount, desc, minPrice, maxPrice, menus: [ { id, name, price, image } ] } ]
// Catatan: Sesuaikan kredensial DB di bagian $mysqli.

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$q = isset($_GET['q']) ? trim($_GET['q']) : '';
if ($q === '') {
    echo json_encode(['success' => true, 'data' => []]);
    exit;
}

$mysqli = new mysqli('localhost', 'root', '', 'dpr_bites');
if ($mysqli->connect_errno) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'DB connection failed']);
    exit;
}
$mysqli->set_charset('utf8mb4');

// Escape untuk LIKE
$like = '%' . $mysqli->real_escape_string($q) . '%';

// Ambil resto yang approved dan cocok di nama/desc atau punya menu yg cocok
$sql = "SELECT g.id_gerai AS id, g.nama_gerai AS name,
                             COALESCE(gp.listing_path, gp.banner_path) AS profilePic,
                             gp.deskripsi_gerai AS deskripsi
                FROM gerai g
                LEFT JOIN gerai_profil gp ON gp.id_gerai = g.id_gerai
                WHERE g.status_pengajuan = 'approved'
                    AND (g.nama_gerai LIKE ? OR gp.deskripsi_gerai LIKE ?
                             OR EXISTS (SELECT 1 FROM etalase e JOIN menu m ON m.id_etalase = e.id_etalase
                                                     WHERE e.id_gerai = g.id_gerai AND m.nama_menu LIKE ?))
                LIMIT 100";

$stmt = $mysqli->prepare($sql);
if (!$stmt) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Prepare failed']);
    exit;
}
$stmt->bind_param('sss', $like, $like, $like);
$stmt->execute();
$res = $stmt->get_result();

$restaurants = [];
$ids = [];
while ($row = $res->fetch_assoc()) {
    $row['profilePic'] = $row['profilePic'] ?: null; // listing_path atau banner_path
    $restaurants[$row['id']] = [
        'id' => $row['id'],
        'name' => $row['name'],
        'profilePic' => $row['profilePic'] ? url_for_image($row['profilePic']) : null,
        'rating' => 0,
        'ratingCount' => 0,
        'desc' => $row['deskripsi'],
        'minPrice' => null,
        'maxPrice' => null,
        'menus' => []
    ];
    $ids[] = $row['id'];
}
$stmt->close();

if (empty($ids)) {
    echo json_encode(['success' => true, 'data' => []]);
    exit;
}

$idList = implode(',', array_map('intval', $ids));
// Rating aggregate (ulasan -> transaksi -> gerai)
$ratingSql = "SELECT g.id_gerai AS id, AVG(u.rating) AS avg_rating, COUNT(u.id_ulasan) AS cnt
              FROM gerai g
              LEFT JOIN transaksi t ON t.id_gerai = g.id_gerai
              LEFT JOIN ulasan u ON u.id_transaksi = t.id_transaksi
              WHERE g.id_gerai IN ($idList)
              GROUP BY g.id_gerai";
$ratingRes = $mysqli->query($ratingSql);
if ($ratingRes instanceof mysqli_result) {
    while ($r = $ratingRes->fetch_assoc()) {
        $id = $r['id'];
        if (isset($restaurants[$id])) {
            $restaurants[$id]['rating'] = $r['avg_rating'] ? round((float)$r['avg_rating'], 2) : 0;
            $restaurants[$id]['ratingCount'] = (int)$r['cnt'];
        }
    }
}

// Ambil harga min & max langsung dari tabel menu
$priceSql = "SELECT m.id_gerai AS id, MIN(m.harga) AS min_harga, MAX(m.harga) AS max_harga
             FROM menu m
             WHERE m.id_gerai IN ($idList)
             GROUP BY m.id_gerai";
$priceRes = $mysqli->query($priceSql);
if ($priceRes instanceof mysqli_result) {
    while ($p = $priceRes->fetch_assoc()) {
        $id = $p['id'];
        if (isset($restaurants[$id])) {
            $restaurants[$id]['minPrice'] = (int)$p['min_harga'];
            $restaurants[$id]['maxPrice'] = (int)$p['max_harga'];
        }
    }
}

// Ambil menu yg cocok query per resto (nama menu LIKE)
$menuSql = "SELECT m.id_gerai AS id_gerai, m.id_menu AS id, m.nama_menu AS name, m.harga AS price, m.gambar_menu AS image
            FROM menu m
            WHERE m.id_gerai IN ($idList) AND m.nama_menu LIKE ?
            LIMIT 500"; // total limit
$menuStmt = $mysqli->prepare($menuSql);
if ($menuStmt) {
    $menuStmt->bind_param('s', $like);
    if ($menuStmt->execute()) {
        $menuRes = $menuStmt->get_result();
        if ($menuRes instanceof mysqli_result) {
            while ($m = $menuRes->fetch_assoc()) {
                $gid = $m['id_gerai'];
                if (isset($restaurants[$gid])) {
                    $restaurants[$gid]['menus'][] = [
                        'id' => $m['id'],
                        'name' => $m['name'],
                        'price' => (int)$m['price'],
                        'image' => $m['image'] ? url_for_image($m['image']) : null,
                    ];
                }
            }
        }
    }
    $menuStmt->close();
}

// Optional: sort menus by name
foreach ($restaurants as &$resto) {
    if (!empty($resto['menus'])) {
        usort($resto['menus'], function($a, $b){ return strcasecmp($a['name'], $b['name']); });
    }
}
unset($resto);

// Ambil buffered warning jika ada
$debugOutput = trim(ob_get_clean());
echo json_encode([
    'success' => true,
    'data' => array_values($restaurants),
    'debug' => $debugOutput !== '' ? $debugOutput : null
]);

function url_for_image($path) {
    if (!$path) return null;
    // Jika sudah full URL (http/https), kembalikan apa adanya
    if (preg_match('~^https?://~i', $path)) return $path;
    // Jika path diawali '/', kita anggap relatif terhadap dokumen root server API
    if ($path[0] === '/') {
        return 'http://10.0.2.2' . $path; // contoh: /images/foto.jpg
    }
    // Jika hanya nama file atau subfolder relative (tidak ada folder uploads khusus), 
    // cukup kembalikan apa adanya atau bisa tambahkan base folder API bila perlu.
    // Di sini kita kembalikan langsung supaya sesuai dengan nilai pada tabel.
    return $path;
}
?>
