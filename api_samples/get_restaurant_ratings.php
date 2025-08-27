<?php
// get_restaurant_ratings.php
// Param: id (id_gerai)
// Return JSON:
// {
//   success: true/false,
//   data: {
//     rating: float,              // rata-rata (0 jika tidak ada)
//     ratingCount: int,           // jumlah ulasan
//     breakdown: [ {star:5,count:..},...,{star:1,count:..} ], // urutan 5->1 seperti UI sekarang
//     reviews: [ {name:"Pengguna", pesanan:"Nasi Goreng, ...", rating:5}, ... ]
//   }
// }
// Jika tidak ada data ulasan: rating=0, ratingCount=0, semua breakdown count=0, reviews=[]

error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING & ~E_DEPRECATED & ~E_STRICT);
ini_set('display_errors', 0);
ob_start();
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($id <= 0) {
    echo json_encode(['success' => false, 'message' => 'Invalid id']);
    exit;
}

$mysqli = new mysqli('localhost', 'root', '', 'dpr_bites');
if ($mysqli->connect_errno) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'DB connection failed']);
    exit;
}
$mysqli->set_charset('utf8mb4');

// Ambil daftar ulasan + pesanan (gabung nama menu yang ada di transaksi tsb)
$ulasanSql = "SELECT u.id_ulasan, u.rating, t.id_transaksi,
       GROUP_CONCAT(DISTINCT m.nama_menu ORDER BY m.nama_menu SEPARATOR ', ') AS pesanan
FROM transaksi t
JOIN ulasan u ON u.id_transaksi = t.id_transaksi
LEFT JOIN transaksi_item ti ON ti.id_transaksi = t.id_transaksi
LEFT JOIN menu m ON m.id_menu = ti.id_menu
WHERE t.id_gerai = ?
GROUP BY u.id_ulasan, u.rating, t.id_transaksi
ORDER BY u.id_ulasan DESC
LIMIT 500";

$reviews = [];
if ($stmt = $mysqli->prepare($ulasanSql)) {
    $stmt->bind_param('i', $id);
    $stmt->execute();
    $res = $stmt->get_result();
    while ($row = $res->fetch_assoc()) {
        $reviews[] = [
            'name' => 'Pengguna', // Placeholder (tidak ada info user di spesifikasi). Sesuaikan jika ada kolom nama.
            'pesanan' => $row['pesanan'] ?: '',
            'rating' => (int)$row['rating'],
        ];
    }
    $stmt->close();
}

$ratingCount = count($reviews);
$sum = 0;
$breakdownCount = [1=>0,2=>0,3=>0,4=>0,5=>0];
foreach ($reviews as $r) {
    $star = (int)$r['rating'];
    if ($star < 1 || $star > 5) $star = 0; // jaga-jaga
    if ($star >=1 && $star <=5) {
        $breakdownCount[$star]++;
        $sum += $star;
    }
}
$avg = $ratingCount > 0 ? round($sum / $ratingCount, 2) : 0;

// Bentuk breakdown urutan 5->1 agar cocok UI dummy
$breakdown = [];
for ($s=5; $s>=1; $s--) {
    $breakdown[] = ['star'=>$s, 'count'=>$breakdownCount[$s]];
}

$data = [
  'rating' => $avg,
  'ratingCount' => $ratingCount,
  'breakdown' => $breakdown,
  'reviews' => $reviews,
];

$debug = trim(ob_get_clean());
echo json_encode([
  'success' => true,
  'data' => $data,
  'debug' => $debug !== '' ? $debug : null,
], JSON_UNESCAPED_UNICODE);

?>
