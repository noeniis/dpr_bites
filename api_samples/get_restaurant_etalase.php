<?php
// get_restaurant_etalase.php
// Param: id (id_gerai)
// Returns: success, data: [ { id, label, image, menuCount } ]
// image may be null (prepare for future column). Only include etalase that belong to the gerai.

error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING & ~E_DEPRECATED & ~E_STRICT);
ini_set('display_errors', 0);
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if($id <= 0){
  echo json_encode(['success'=>false,'message'=>'Invalid id']);
  exit;
}

$mysqli = new mysqli('localhost','root','', 'dpr_bites');
if($mysqli->connect_errno){
  http_response_code(500);
  echo json_encode(['success'=>false,'message'=>'DB connection failed']);
  exit;
}
$mysqli->set_charset('utf8mb4');

// Detect optional image column
$cols = [];$resCols=$mysqli->query("SHOW COLUMNS FROM etalase");
if($resCols){ while($c=$resCols->fetch_assoc()){ $cols[strtolower($c['Field'])]=true; } }
$imgSelect = isset($cols['image']) ? ', e.image' : ', NULL AS image';

$sql = "SELECT e.id_etalase AS id, e.nama_etalase AS label $imgSelect, 
  (SELECT COUNT(*) FROM menu m WHERE m.id_etalase = e.id_etalase) AS menuCount
  FROM etalase e
  WHERE e.id_gerai = ?
  HAVING menuCount > 0
  ORDER BY e.nama_etalase ASC LIMIT 200";
$stmt = $mysqli->prepare($sql);
if(!$stmt){
  echo json_encode(['success'=>false,'message'=>'Prepare failed']);
  exit;
}
$stmt->bind_param('i',$id);
$stmt->execute();
$res = $stmt->get_result();
$list = [];
while($row=$res->fetch_assoc()){
  $list[] = [
    'id' => (int)$row['id'],
    'label' => $row['label'],
    'image' => $row['image'],
    'menuCount' => (int)$row['menuCount']
  ];
}
$stmt->close();

echo json_encode(['success'=>true,'data'=>$list]);
?>
