<?php
date_default_timezone_set('Asia/Jakarta');
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

$out = ['success'=>false,'message'=>'','data'=>[]];
$mysqli = @new mysqli('localhost','root','','dpr_bites');
if ($mysqli->connect_errno) { $out['message']='DB connection failed'; echo json_encode($out); exit; }
$mysqli->set_charset('utf8mb4');

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($userId<=0) { $out['message']='Missing user_id'; echo json_encode($out); exit; }

// Subquery rating per gerai
$ratingSub = "SELECT t.id_gerai, AVG(u.rating) AS avg_rating, COUNT(u.id_ulasan) AS rating_count
              FROM ulasan u
              JOIN transaksi t ON t.id_transaksi = u.id_transaksi
              GROUP BY t.id_gerai";

// Subquery price range per gerai (min & max menu price)
$priceSub = "SELECT id_gerai, MIN(harga) AS min_price, MAX(harga) AS max_price
             FROM menu
             GROUP BY id_gerai";

$sql = "SELECT f.id_menu,
           m.nama_menu, m.deskripsi_menu, m.harga, m.gambar_menu,
           g.id_gerai, g.nama_gerai, gp.deskripsi_gerai,
           COALESCE(r.avg_rating,0) AS rating, COALESCE(r.rating_count,0) AS rating_count,
           COALESCE(p.min_price,0) AS min_price, COALESCE(p.max_price,0) AS max_price
    FROM favorite f
    JOIN menu m ON m.id_menu = f.id_menu
    JOIN gerai g ON g.id_gerai = m.id_gerai
    LEFT JOIN gerai_profil gp ON gp.id_gerai = g.id_gerai
    LEFT JOIN ($ratingSub) r ON r.id_gerai = g.id_gerai
    LEFT JOIN ($priceSub) p ON p.id_gerai = g.id_gerai
    WHERE f.id_users=?
    ORDER BY f.id_favorite DESC";

$st = $mysqli->prepare($sql);
$st->bind_param('i',$userId);
$st->execute();
$rs = $st->get_result();
$data = [];
while ($row = $rs->fetch_assoc()) {
    $data[] = [
        'menu_id'        => (int)$row['id_menu'],
        'name'           => $row['nama_menu'],
        'desc'           => $row['deskripsi_menu'],
        'price'          => (int)$row['harga'],
        'image'          => $row['gambar_menu'],
        'restaurant'     => [
            'id'         => (int)$row['id_gerai'],
            'name'       => $row['nama_gerai'],
            'desc'       => $row['deskripsi_gerai'],
            'rating'     => (float)$row['rating'],
            'ratingCount'=> (int)$row['rating_count'],
            'minPrice'   => (int)$row['min_price'],
            'maxPrice'   => (int)$row['max_price'],
        ],
    ];
}
$st->close();

$out['success']=true;
$out['data']=$data;
echo json_encode($out);
?>