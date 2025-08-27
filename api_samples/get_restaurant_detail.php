<?php
// get_restaurant_detail.php
// Param: id (id_gerai)
// Return: success, data: { id, name, profilePic, bannerPic, rating, ratingCount, minPrice, maxPrice,
//                         etalase:[{id,label,image}], menus:[{id,name,price,image,desc,etalase_label,orderCount,recommended}] }
// Catatan: image path dibiarkan apa adanya; jika full URL (http/https) dipakai langsung.

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

// Ambil data gerai + profil (hanya approved) dengan kolom opsional aman jika belum ditambahkan di DB
$existingCols = [];
$colRes = $mysqli->query("SHOW COLUMNS FROM gerai_profil");
if($colRes){
    while($c = $colRes->fetch_assoc()){
        $existingCols[strtolower($c['Field'])] = true;
    }
}
$optional = [];
foreach(['hari_buka','jam_buka','jam_tutup','latitude','longitude'] as $c){
    if(isset($existingCols[$c])){ $optional[] = "gp.$c"; }
}
$selectOptional = '';
if(!empty($optional)){
    $selectOptional = ",\n               " . implode(", ", $optional);
}
$sql = "SELECT g.id_gerai AS id, g.nama_gerai AS name,\n               gp.listing_path, gp.banner_path, gp.deskripsi_gerai AS deskripsi$selectOptional\n        FROM gerai g\n        LEFT JOIN gerai_profil gp ON gp.id_gerai = g.id_gerai\n        WHERE g.id_gerai = ? AND g.status_pengajuan = 'approved' LIMIT 1";
$stmt = $mysqli->prepare($sql);
if(!$stmt){
    echo json_encode(['success'=>false,'message'=>'Prepare failed']);
    exit;
}
$stmt->bind_param('i',$id);
$stmt->execute();
$res = $stmt->get_result();
$resto = $res->fetch_assoc();
$stmt->close();
if(!$resto){
    echo json_encode(['success'=>false,'message'=>'Resto not found / not approved']);
    exit;
}

// Rating aggregate
$ratingSql = "SELECT AVG(u.rating) AS avg_rating, COUNT(u.id_ulasan) AS cnt
              FROM transaksi t
              LEFT JOIN ulasan u ON u.id_transaksi = t.id_transaksi
              WHERE t.id_gerai = ?";
$rs = $mysqli->prepare($ratingSql);
$avg=0;$cnt=0;
if($rs){
    $rs->bind_param('i',$id);
    $rs->execute();
    $rres = $rs->get_result();
    if($row=$rres->fetch_assoc()){
        $avg = $row['avg_rating']? round((float)$row['avg_rating'],2):0;
        $cnt = (int)$row['cnt'];
    }
    $rs->close();
}

// Harga min max
$priceSql = "SELECT MIN(harga) AS mn, MAX(harga) AS mx FROM menu WHERE id_gerai = ?";
$ps = $mysqli->prepare($priceSql);
$minP=null;$maxP=null;
if($ps){
    $ps->bind_param('i',$id);
    $ps->execute();
    $pr = $ps->get_result();
    if($row=$pr->fetch_assoc()){
        $minP = $row['mn']!==null? (int)$row['mn']:null;
        $maxP = $row['mx']!==null? (int)$row['mx']:null;
    }
    $ps->close();
}

// Etalase list
$etalase = [];
$etRes = $mysqli->prepare("SELECT id_etalase, nama_etalase FROM etalase WHERE id_gerai = ? LIMIT 100");
if($etRes){
    $etRes->bind_param('i',$id);
    $etRes->execute();
    $er = $etRes->get_result();
    while($e=$er->fetch_assoc()){
        $etalase[] = [
            'id'=>$e['id_etalase'],
            'label'=>$e['nama_etalase'],
            'image'=>null // placeholder jika nanti ada kolom gambar
        ];
    }
    $etRes->close();
}

// Menu beserta order count (frequently ordered) -> hitung jumlah di transaksi_item
$menuSql = "SELECT m.id_menu AS id, m.nama_menu AS name, m.harga AS price, m.gambar_menu AS image,
                   m.deskripsi_menu AS deskripsi, m.kategori,
                   e.nama_etalase AS etalase_label,
                   COALESCE(SUM(ti.jumlah),0) AS orderCount
            FROM menu m
            LEFT JOIN etalase e ON e.id_etalase = m.id_etalase
            LEFT JOIN transaksi_item ti ON ti.id_menu = m.id_menu
            LEFT JOIN transaksi t ON t.id_transaksi = ti.id_transaksi
            WHERE m.id_gerai = ?
            GROUP BY m.id_menu
            ORDER BY name ASC
            LIMIT 1000";
$menus = [];
$ms = $mysqli->prepare($menuSql);
if($ms){
    $ms->bind_param('i',$id);
    $ms->execute();
    $mr = $ms->get_result();
    while($m=$mr->fetch_assoc()){
        $menus[] = [
            'id'=>$m['id'],
            'name'=>$m['name'],
            'price'=>(int)$m['price'],
            'image'=>$m['image']? url_for_image($m['image']):null,
            'desc'=>$m['deskripsi'],
            'kategori'=>$m['kategori'],
            'etalase_label'=>$m['etalase_label'] ?: $m['kategori'],
            'orderCount'=>(int)$m['orderCount'],
            'recommended'=>false
        ];
    }
    $ms->close();
}

// Tentukan recommended di server: hanya jika ada transaksi (orderCount > 0), ambil maksimal 2 menu paling sering dipesan.
$orderedWithCount = array_filter($menus, function($m){ return ($m['orderCount'] ?? 0) > 0; });
if(!empty($orderedWithCount)){
    usort($orderedWithCount, function($a,$b){ return ($b['orderCount'] <=> $a['orderCount']); });
    $limit = 0;
    $recommendedIds = [];
    foreach($orderedWithCount as $m){
        if($limit >= 2) break;
        $recommendedIds[$m['id']] = true;
        $limit++;
    }
    // Tandai di array asli tanpa mengubah urutan asli.
    foreach($menus as &$m){
        if(isset($recommendedIds[$m['id']])){
            $m['recommended'] = true;
        }
    }
    unset($m);
}

// Derive openDays from SET field hari_buka (e.g. 'Senin,Selasa,Rabu,Kamis,Jumat') jika kolom tersedia
$openDays = null;
if(!empty($resto['hari_buka'])){
    // Normalize: split by comma, trim, keep order based on predefined week order
    $rawDays = array_filter(array_map('trim', explode(',', $resto['hari_buka'])));
    $weekOrder = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    // Build ordered unique list
    $selected = [];
    foreach($weekOrder as $d){
        foreach($rawDays as $rd){
            if(strcasecmp($d,$rd)==0){ $selected[] = $d; break; }
        }
    }
    if(count($selected)===1){
        $openDays = $selected[0];
    } elseif(count($selected)===7){
        $openDays = 'Senin - Minggu';
    } elseif(count($selected) > 1){
        // Check if contiguous block
        $indexes = array_map(function($d) use ($weekOrder){ return array_search($d,$weekOrder); }, $selected);
        sort($indexes);
        $contiguous = true;
        for($i=1;$i<count($indexes);$i++){
            if($indexes[$i] !== $indexes[$i-1]+1){ $contiguous = false; break; }
        }
        if($contiguous){
            $openDays = $selected[0] . ' - ' . end($selected);
        } else {
            $openDays = implode(', ', $selected);
        }
    }
}
$data = [
  'id' => $resto['id'],
  'name' => $resto['name'],
  'profilePic' => $resto['listing_path']? url_for_image($resto['listing_path']): null,
  'bannerPic' => $resto['banner_path']? url_for_image($resto['banner_path']): null,
  'desc' => $resto['deskripsi'],
  'rating' => $avg,
  'ratingCount' => $cnt,
  'minPrice' => $minP,
  'maxPrice' => $maxP,
  'openDays' => $openDays,
        'openTime' => isset($resto['jam_buka']) ? format_hhmm($resto['jam_buka']) : null,
        'closeTime' => isset($resto['jam_tutup']) ? format_hhmm($resto['jam_tutup']) : null,
  'etalase' => $etalase,
    'menus' => $menus,
        'latitude' => isset($resto['latitude']) ? (float)$resto['latitude'] : null,
        'longitude' => isset($resto['longitude']) ? (float)$resto['longitude'] : null
];

$debug = trim(ob_get_clean());
echo json_encode([
  'success'=> true,
  'data'=> $data,
  'debug'=> $debug !== '' ? $debug : null
]);

function url_for_image($path){
  if(!$path) return null;
  if(preg_match('~^https?://~i',$path)) return $path;
  if($path[0] === '/') return 'http://10.0.2.2' . $path;
  return $path; // relative or filename only
}

function format_hhmm($time){
    if(!$time) return null;
    if(preg_match('/^(\d{2}:\d{2})/',$time,$m)) return $m[1];
    // fallback: if time like H:i:s without leading zero
    if(preg_match('/^(\d{1,2}:\d{2})/',$time,$m)) return $m[1];
    return $time;
}
?>
