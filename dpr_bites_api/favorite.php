<?php
date_default_timezone_set('Asia/Jakarta');
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

$out = ['success'=>false,'message'=>'','favorited'=>false];
$mysqli = @new mysqli('localhost','root','','dpr_bites');
if ($mysqli->connect_errno) { $out['message']='DB connection failed'; echo json_encode($out); exit; }
$mysqli->set_charset('utf8mb4');

$method = $_SERVER['REQUEST_METHOD'];
$userId = 0; $menuId = 0; $action = '';
if ($method === 'GET') {
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    $menuId = isset($_GET['menu_id']) ? (int)$_GET['menu_id'] : 0;
    $action = isset($_GET['action']) ? trim($_GET['action']) : '';
} else { // POST JSON / form
    $raw = file_get_contents('php://input');
    $payload = json_decode($raw,true);
    if (!is_array($payload)) $payload = $_POST;
    $userId = isset($payload['user_id']) ? (int)$payload['user_id'] : 0;
    $menuId = isset($payload['menu_id']) ? (int)$payload['menu_id'] : 0;
    $action = isset($payload['action']) ? trim($payload['action']) : '';
}

if ($userId<=0 || $menuId<=0) { $out['message']='Missing user_id/menu_id'; echo json_encode($out); exit; }

// Ensure menu exists
$chk = $mysqli->prepare("SELECT id_menu FROM menu WHERE id_menu=? LIMIT 1");
$chk->bind_param('i',$menuId); $chk->execute(); $rs=$chk->get_result();
if (!$rs || $rs->num_rows===0) { $out['message']='Menu not found'; echo json_encode($out); exit; }
$chk->close();

// Check existing favorite
$favExists = false; $favId = null;
$q = $mysqli->prepare("SELECT id_favorite FROM favorite WHERE id_users=? AND id_menu=? LIMIT 1");
$q->bind_param('ii',$userId,$menuId); $q->execute(); $rq=$q->get_result();
if ($rq && $rq->num_rows>0) { $row=$rq->fetch_assoc(); $favExists=true; $favId=(int)$row['id_favorite']; }
$q->close();

// Determine desired behavior
// action: add | remove | toggle | '' (empty => toggle)
if ($method==='GET' && $action==='') {
    $out['success']=true; $out['favorited']=$favExists; echo json_encode($out); exit;
}

if ($action==='') $action='toggle';

try {
    if ($action==='add') {
        if (!$favExists) {
            $ins = $mysqli->prepare("INSERT INTO favorite (id_users,id_menu) VALUES (?,?)");
            $ins->bind_param('ii',$userId,$menuId); $ins->execute(); $ins->close();
            $favExists = true;
        }
    } elseif ($action==='remove') {
        if ($favExists) {
            $del = $mysqli->prepare("DELETE FROM favorite WHERE id_users=? AND id_menu=?");
            $del->bind_param('ii',$userId,$menuId); $del->execute(); $del->close();
            $favExists = false;
        }
    } elseif ($action==='toggle') {
        if ($favExists) {
            $del = $mysqli->prepare("DELETE FROM favorite WHERE id_users=? AND id_menu=?");
            $del->bind_param('ii',$userId,$menuId); $del->execute(); $del->close();
            $favExists = false;
        } else {
            $ins = $mysqli->prepare("INSERT INTO favorite (id_users,id_menu) VALUES (?,?)");
            $ins->bind_param('ii',$userId,$menuId); $ins->execute(); $ins->close();
            $favExists = true;
        }
    } else {
        $out['message']='Invalid action'; echo json_encode($out); exit;
    }
    $out['success']=true;
    $out['favorited']=$favExists;
} catch (Throwable $e) {
    $out['message']='Error: '.$e->getMessage();
}

echo json_encode($out);
?>