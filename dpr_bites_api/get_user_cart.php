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

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($userId<=0) { $out['message']='Missing user_id'; echo json_encode($out); exit; }

// Ambil semua keranjang aktif user (bisa multi gerai)
$carts = [];
$sqlCart = "SELECT k.id_keranjang,k.id_gerai,COALESCE(g.nama_gerai,'') AS nama_gerai
             FROM keranjang k
             LEFT JOIN gerai g ON g.id_gerai = k.id_gerai
             WHERE k.id_users=? AND k.status='aktif'
             ORDER BY k.id_keranjang DESC";
$stCart = $mysqli->prepare($sqlCart);
$stCart->bind_param('i',$userId);
$stCart->execute();
$rsCart = $stCart->get_result();
while ($rsCart && $row = $rsCart->fetch_assoc()) {
    $carts[] = [
        'id_keranjang'=>(int)$row['id_keranjang'],
        'id_gerai'=>(int)$row['id_gerai'],
        'nama_gerai'=>$row['nama_gerai'] !== '' ? $row['nama_gerai'] : ('Gerai #'.$row['id_gerai']),
    ];
}
$stCart->close();

$result = [];
foreach ($carts as $cart) {
    $keranjangId = $cart['id_keranjang'];
    $geraiId = $cart['id_gerai'];
    $restaurantName = $cart['nama_gerai'];

    // Ambil item-item dalam keranjang ini
    $menus = [];
    $sqlItems = "SELECT ki.id_keranjang_item, ki.id_menu, ki.qty, ki.harga_satuan, ki.subtotal, ki.note,
                        m.nama_menu, m.deskripsi_menu, m.gambar_menu, m.harga AS base_price
                 FROM keranjang_item ki
                 JOIN menu m ON m.id_menu = ki.id_menu
                 WHERE ki.id_keranjang=?";
    $stIt = $mysqli->prepare($sqlItems);
    $stIt->bind_param('i',$keranjangId);
    $stIt->execute();
    $rsIt = $stIt->get_result();
    while ($rsIt && $rowIt = $rsIt->fetch_assoc()) {
        $keranjangItemId = (int)$rowIt['id_keranjang_item'];
        $menuId = (int)$rowIt['id_menu'];

        // Ambil addon terpilih untuk item ini
        $selectedAddonIds = [];
        $selectedAddons = [];
        $sel = $mysqli->prepare("SELECT kia.id_addon,a.nama_addon,a.harga,a.image_path FROM keranjang_item_addon kia JOIN addon a ON a.id_addon=kia.id_addon WHERE kia.id_keranjang_item=? ORDER BY kia.id_addon ASC");
        $sel->bind_param('i',$keranjangItemId);
        $sel->execute();
        $rsSel = $sel->get_result();
        $addonPriceSum = 0;
        while ($rsSel && $ra = $rsSel->fetch_assoc()) {
            $aid = (int)$ra['id_addon'];
            $selectedAddonIds[] = $aid;
            $selectedAddons[] = $ra['nama_addon']; // label list untuk UI field 'addon'
            $addonPriceSum += (int)$ra['harga'];
        }
        $sel->close();

        // Ambil semua opsi addon yang valid untuk menu (untuk dialog edit)
        $addonOptions = [];
        $opt = $mysqli->prepare("SELECT a.id_addon,a.nama_addon,a.harga,a.image_path FROM menu_addon ma JOIN addon a ON a.id_addon=ma.id_addon WHERE ma.id_menu=? ORDER BY a.id_addon ASC");
        $opt->bind_param('i',$menuId);
        $opt->execute();
        $rsOpt = $opt->get_result();
        while ($rsOpt && $ro = $rsOpt->fetch_assoc()) {
            $addonOptions[] = [
                'id'=>(int)$ro['id_addon'],
                'label'=>$ro['nama_addon'],
                'price'=>(int)$ro['harga'],
                'image'=>$ro['image_path'],
            ];
        }
        $opt->close();

        // Bentuk struktur menu sesuai dummy (price base, addonPrice terpisah, addon list label)
        $menus[] = [
            'id_keranjang_item'=>$keranjangItemId,
            'menu_id'=>$menuId,
            'name'=>$rowIt['nama_menu'],
            'desc'=>$rowIt['deskripsi_menu'],
            'image'=>$rowIt['gambar_menu'],
            'price'=>(int)$rowIt['base_price'],
            'qty'=>(int)$rowIt['qty'],
            'addon'=>$selectedAddons,          // list label addon terpilih
            'addonPrice'=>$addonPriceSum,       // total harga addon terpilih
            'addonOptions'=>$addonOptions,      // semua opsi addon untuk menu ini
            'note'=>$rowIt['note'],             // catatan per item
        ];
    }
    $stIt->close();

    if (!empty($menus)) {
        $result[] = [
            'id_keranjang'=>$keranjangId,
            'id_gerai'=>$geraiId,
            'restaurantName'=>$restaurantName,
            'estimate'=>'15-20 menit', // placeholder; sesuaikan jika ada kolom estimasi
            'menus'=>$menus,
        ];
    }
}

$out['success']=true;
$out['data']=$result; // sama bentuknya dengan carts dummy (list restoran)
echo json_encode($out);
?>
