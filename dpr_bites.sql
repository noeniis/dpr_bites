-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 15, 2025 at 11:09 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `dpr_bites`
--

-- --------------------------------------------------------

--
-- Table structure for table `addon`
--

CREATE TABLE `addon` (
  `id_addon` int(11) NOT NULL,
  `id_gerai` int(11) NOT NULL,
  `nama_addon` varchar(100) NOT NULL,
  `harga` int(11) NOT NULL,
  `deskripsi` text DEFAULT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `stok` int(11) NOT NULL,
  `tersedia` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `addon`
--

INSERT INTO `addon` (`id_addon`, `id_gerai`, `nama_addon`, `harga`, `deskripsi`, `image_path`, `created_at`, `stok`, `tersedia`) VALUES
(7, 3, 'puding', 6000, 'puding rasa cokelat', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1755961599/br5sodzx3hczoezcqm96.jpg', '2025-08-23 22:06:38', 3, 1),
(9, 3, 'Minuman green tea', 7000, 'minuman green tea 250 ml', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756007739/bzvadm7wiuqch8vwo3hb.jpg', '2025-08-24 10:55:38', 13, 1),
(14, 3, 'Susu kotak pisang', 6000, '', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756191072/t0ezo6dfcfjqrw2rwikz.jpg', '2025-08-26 13:51:13', 25, 1),
(15, 3, 'Roti Abon', 8000, 'Roti Abon', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756193435/upwwnr9ayz29saosbhho.jpg', '2025-08-26 13:57:48', 3, 1),
(17, 8, 'Bakso', 8000, 'Bakso is 2', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756977809/nk81xz17w4slzqphnikj.jpg', '2025-09-04 16:23:28', 20, 1),
(18, 9, 'Telur', 6000, 'telur rebus', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757046857/basit6eivyaq8mtsyson.jpg', '2025-09-05 11:34:17', 10, 1),
(19, 9, 'Ice cream', 22000, 'matcha', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757132881/cfkyuphyisuioedqulxs.jpg', '2025-09-06 11:28:01', 20, 1),
(20, 3, 'Snack', 6000, 'snack', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757140032/ker5gbcb3xkckrjnnsmt.jpg', '2025-09-06 13:27:12', 8, 1),
(21, 10, 'Bakso', 8000, 'Bakso Kuah', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757218469/gec5aic8fhs1nxeqsyyg.jpg', '2025-09-07 11:14:30', 10, 1),
(22, 10, 'Roti', 8000, 'roti', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757220440/fe9oybvee3kxoc4uy4qc.jpg', '2025-09-07 11:47:21', 10, 1),
(23, 11, 'puding', 10000, 'puding cokelat', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757221667/xqtxuk7dfzhvyk5oamkd.jpg', '2025-09-07 12:07:48', 5, 1),
(24, 13, 'Ayam', 9000, 'ayam', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757302876/wxf2b9rpavsv3abyukfs.jpg', '2025-09-08 10:41:16', 10, 1),
(25, 14, 'Bakso', 8000, 'bakso', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757314754/bctivprya8862xwnc3wn.jpg', '2025-09-08 13:59:14', 20, 1);

-- --------------------------------------------------------

--
-- Table structure for table `alamat_pengantaran`
--

CREATE TABLE `alamat_pengantaran` (
  `id_alamat` int(11) NOT NULL,
  `id_users` int(11) NOT NULL,
  `nama_penerima` varchar(50) DEFAULT NULL,
  `nama_gedung` varchar(100) DEFAULT NULL,
  `detail_pengantaran` text DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `no_hp` varchar(13) DEFAULT NULL,
  `alamat_utama` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `alamat_pengantaran`
--

INSERT INTO `alamat_pengantaran` (`id_alamat`, `id_users`, `nama_penerima`, `nama_gedung`, `detail_pengantaran`, `latitude`, `longitude`, `no_hp`, `alamat_utama`, `created_at`, `updated_at`) VALUES
(2, 1, 'ytut', 'pppp9', 'uyu', -6.20759597, 106.80245174, '0282555558588', 0, '2025-08-20 14:33:15', '2025-08-26 19:56:07'),
(3, 1, 'poiuytre', 'yyyyn', 'ppppp', -6.20983356, 106.79947479, '2541558633', 0, '2025-08-20 15:33:39', '2025-08-20 17:11:09'),
(4, 1, 'Raihan', 'Gedung Nusantara II', 'Lantai 3, Ruangan dekat lift', -6.20973391, 106.79917042, '085155156620', 1, '2025-08-20 17:11:09', '2025-08-26 19:56:07');

-- --------------------------------------------------------

--
-- Table structure for table `etalase`
--

CREATE TABLE `etalase` (
  `id_etalase` int(11) NOT NULL,
  `id_gerai` int(11) NOT NULL,
  `nama_etalase` varchar(100) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `etalase`
--

INSERT INTO `etalase` (`id_etalase`, `id_gerai`, `nama_etalase`, `created_at`) VALUES
(1, 3, 'Jajanan', '2025-08-24 10:47:52'),
(3, 3, 'Minuman', '2025-08-24 10:48:41'),
(5, 3, 'Camilan', '2025-08-26 13:02:54'),
(7, 3, 'Makanan', '2025-08-26 13:13:27'),
(10, 5, 'Jajanan SD', '2025-08-30 16:02:03'),
(15, 8, 'Ayam', '2025-09-04 16:16:54'),
(16, 9, 'Makanan Berkuah', '2025-09-05 11:33:33'),
(17, 9, 'Ayam', '2025-09-06 11:10:34'),
(19, 3, 'Ayam', '2025-09-06 13:45:46'),
(20, 9, 'Minuman', '2025-09-06 13:51:00'),
(21, 10, 'Paket Ayam', '2025-09-07 11:13:58'),
(22, 10, 'Camilan', '2025-09-07 11:16:42'),
(23, 10, 'Es', '2025-09-07 11:43:00'),
(24, 10, 'Makanan', '2025-09-07 11:46:32'),
(26, 11, 'Roti', '2025-09-07 12:07:18'),
(27, 12, 'Makanan', '2025-09-07 12:19:20'),
(28, 13, 'Makanan Berat', '2025-09-08 10:40:42'),
(29, 14, 'Makanan Berat', '2025-09-08 13:58:30');

-- --------------------------------------------------------

--
-- Table structure for table `favorite`
--

CREATE TABLE `favorite` (
  `id_favorite` int(11) NOT NULL,
  `id_users` int(11) NOT NULL,
  `id_menu` int(11) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `favorite`
--

INSERT INTO `favorite` (`id_favorite`, `id_users`, `id_menu`, `created_at`, `updated_at`) VALUES
(3, 1, 4, '2025-08-26 18:06:07', '2025-08-26 18:06:07');

-- --------------------------------------------------------

--
-- Table structure for table `gerai`
--

CREATE TABLE `gerai` (
  `id_gerai` int(11) NOT NULL,
  `id_users` int(11) NOT NULL,
  `nama_gerai` varchar(100) NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `detail_alamat` text DEFAULT NULL,
  `telepon` varchar(100) NOT NULL,
  `qris_path` varchar(255) DEFAULT NULL,
  `status_pengajuan` enum('pending','approved','rejected') DEFAULT 'pending',
  `sertifikasi_halal` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `alasan_tolak` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `gerai`
--

INSERT INTO `gerai` (`id_gerai`, `id_users`, `nama_gerai`, `latitude`, `longitude`, `detail_alamat`, `telepon`, `qris_path`, `status_pengajuan`, `sertifikasi_halal`, `created_at`, `updated_at`, `alasan_tolak`) VALUES
(1, 1, 'Waroenk Noeni', 123.0000000, 123.0000000, 'JL. Merdeka 1', '0862528293', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/qris-default_lr9x0g.jpg', 'approved', 0, '2025-08-20 11:28:09', '2025-08-26 15:20:07', ''),
(2, 2, 'Waroenk Noeni', 123.0000000, 123.0000000, 'JL. Merdeka 3', '0862528293', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/qris-default_lr9x0g.jpg', 'rejected', 0, '2025-08-20 11:28:09', '2025-08-26 15:20:07', 'Data tidak valid; Dokumen tidak sesuai'),
(3, 5, 'Waroenk Sila', 123.0000000, 123.0000000, 'JL. Maju 10', '0862528293', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/qris-default_lr9x0g.jpg', 'approved', 0, '2025-08-20 11:28:09', '2025-08-26 15:20:40', ''),
(5, 12, 'Warung Makan Farah', 123.0000000, 123.0000000, 'Kantin Pujasera', '089689388', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/qris-default_lr9x0g.jpg', 'approved', 0, '2025-08-20 11:28:09', '2025-08-26 15:20:40', ''),
(6, 13, 'Warung Laura', 123.0000000, 123.0000000, 'Kantin Pujasera', '089689388', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/qris-default_lr9x0g.jpg', 'approved', 0, '2025-08-20 11:28:09', '2025-08-26 15:20:40', ''),
(8, 14, 'Kedai Bersama', -6.2110363, 106.7978352, 'Kantin Risanti', '08264714', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756974144/ib2tagwecqgbpvqqwst1.png', 'approved', 1, '2025-09-04 13:00:04', '2025-09-04 15:45:49', ''),
(9, 15, 'Rumah Makan Nina', -6.2110363, 106.7982956, 'Kantin Pujasera', '0867278433', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757046703/afdr2sfm5pcxij2myfb3.png', 'approved', 1, '2025-09-04 17:18:36', '2025-09-05 11:32:28', ''),
(10, 16, 'Warung Sunda', -6.2098462, 106.8001840, 'Kantin Risanti ', '08627484', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757168410/hdnu6ijnxkoofs8n8rfk.png', 'approved', 1, '2025-09-06 20:56:14', '2025-09-07 11:12:31', ''),
(11, 17, 'Rumah Makan Kinan', -6.2113078, 106.7996221, 'Kantin Pujasera Blok B', '', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757221527/dclerdljisfv7evyxqos.png', 'approved', 1, '2025-09-07 11:52:04', '2025-09-07 12:06:46', ''),
(12, 9, 'Warung Bu Ayu', -6.2100669, 106.7986934, 'Kantin Risanti', '', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757222233/yre8m7qklteo4fu3qcqo.png', 'approved', 1, '2025-09-07 12:16:33', '2025-09-07 12:18:40', ''),
(13, 18, 'Warung Pojok Hasan', -6.2083215, 106.7981004, 'Kantin Belakang Masjid', '08283749292', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757302016/skcyrsvgqiknejaobk2z.png', 'approved', 1, '2025-09-08 10:24:56', '2025-09-08 10:39:53', ''),
(14, 19, 'Warung Kandar', -6.2093762, 106.7986934, 'Kantin Pujasera', '', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757314367/e7wikjuxkklrgepdgl1x.png', 'approved', 0, '2025-09-08 13:51:28', '2025-09-08 13:57:43', ''),
(16, 23, 'Makan Kenyang', -6.2089422, 106.8013307, 'Foodcourt', '', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757926637/joz0zm4pudefcmjhydaa.jpg', 'rejected', 1, '2025-09-15 15:56:25', '2025-09-15 16:06:56', 'Dokumen tidak sesuai');

-- --------------------------------------------------------

--
-- Table structure for table `gerai_profil`
--

CREATE TABLE `gerai_profil` (
  `id_gerai_profil` int(11) NOT NULL,
  `id_gerai` int(11) NOT NULL,
  `banner_path` varchar(255) DEFAULT NULL,
  `listing_path` varchar(255) DEFAULT NULL,
  `deskripsi_gerai` text DEFAULT NULL,
  `hari_buka` set('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu') NOT NULL,
  `jam_buka` time NOT NULL,
  `jam_tutup` time NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `gerai_profil`
--

INSERT INTO `gerai_profil` (`id_gerai_profil`, `id_gerai`, `banner_path`, `listing_path`, `deskripsi_gerai`, `hari_buka`, `jam_buka`, `jam_tutup`, `created_at`, `updated_at`) VALUES
(1, 1, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/banner-default_qbci0v.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/listing-default_srebux.png', 'sfdghj', 'Senin', '15:30:26', '19:30:26', '2025-08-23 11:31:51', '2025-08-26 15:20:08'),
(2, 2, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/banner-default_qbci0v.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/listing-default_srebux.png', 'sfdghj', 'Senin', '15:30:26', '19:30:26', '2025-08-23 11:31:51', '2025-08-26 15:20:08'),
(3, 3, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757311049/iy2ryalsfdiullfofqym.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/listing-default_srebux.png', 'Ayam, Camilan, Minuman', 'Senin,Selasa,Rabu,Kamis', '09:30:00', '16:30:00', '2025-08-23 11:31:51', '2025-09-15 15:48:57'),
(5, 5, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756544576/rz8q6uga3rsiwi3hhi8e.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/listing-default_srebux.png', 'Ayam, Camilan, Minuman', 'Senin,Selasa,Rabu,Kamis,Jumat', '08:30:00', '04:30:00', '2025-08-23 11:31:51', '2025-08-30 16:02:56'),
(20, 6, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756709324/fazzlkarecghxa1xyeqw.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756709326/oh5paajikbxeoc3cikn7.jpg', 'Ayam, Nasi', 'Senin,Selasa,Rabu', '08:00:00', '03:00:00', '2025-09-01 13:48:46', '2025-09-01 13:48:46'),
(21, 8, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756975251/lqx4xrspwrqhlsznxxpq.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756975253/tnuebtmdofwoqw7wyqfn.jpg', 'Ayam, Jajanan, Kopi', 'Senin,Rabu,Jumat', '09:00:00', '19:00:00', '2025-09-04 15:40:52', '2025-09-04 16:47:58'),
(22, 9, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757046729/wozxaxuu5bunfyi0r94u.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756981401/znepldqbtuf6vpzwzflt.jpg', 'Mie Ayam, Bakso, Nasi', 'Senin,Selasa,Rabu,Kamis', '08:00:00', '16:00:00', '2025-09-04 17:23:19', '2025-09-06 09:43:00'),
(28, 10, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757216878/g14uf8o2zv211obh9069.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757218654/tglvt82rwnwa5csadc7g.jpg', 'Jajanan, Kopi', 'Senin,Selasa,Rabu,Kamis', '09:00:00', '16:00:00', '2025-09-07 10:48:00', '2025-09-07 11:17:35'),
(29, 11, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757221584/mavrxyugtzo0wb8mdmmk.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757221585/r6tjhisksqcx3lfshliw.jpg', 'Camilan, Mie Ayam, Bakso', 'Senin,Rabu,Kamis,Jumat', '10:00:00', '14:00:00', '2025-09-07 12:06:26', '2025-09-07 12:08:14'),
(30, 12, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757222270/jlduz6acusjeyguu0pnw.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757222272/kafo9wfkfvvvtoeeszpa.jpg', 'Jajanan, Camilan, Kopi', 'Senin,Rabu,Jumat', '10:00:00', '16:00:00', '2025-09-07 12:17:53', '2025-09-07 12:17:53'),
(31, 13, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757302926/zx2myycb8e6tdwsj7skb.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757302254/vvjmzvemy8bd56jfuyjh.jpg', 'Jajanan, Camilan, Mie Ayan', 'Senin,Selasa,Rabu,Kamis', '08:00:00', '17:00:00', '2025-09-08 10:30:54', '2025-09-08 10:42:06'),
(32, 14, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757314427/cxhozkkqwm4qiptvuyrl.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757314432/t7bzzropuitjqdsy04cp.jpg', 'Mie Ayam, Nasi', 'Senin,Rabu,Kamis', '08:00:00', '16:00:00', '2025-09-08 13:53:52', '2025-09-08 14:01:02'),
(35, 16, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757926665/sikownwcgsfwwqfe3fau.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757926667/ofx49ef0ffhhhqtpnrig.jpg', 'Ayam, Bakso', 'Senin,Selasa,Kamis,Jumat', '08:00:00', '16:00:00', '2025-09-15 15:57:48', '2025-09-15 15:57:48');

-- --------------------------------------------------------

--
-- Table structure for table `keranjang`
--

CREATE TABLE `keranjang` (
  `id_keranjang` int(11) NOT NULL,
  `id_users` int(11) NOT NULL,
  `id_gerai` int(11) NOT NULL,
  `status` enum('aktif','checkout','expired') DEFAULT 'aktif',
  `total_harga` int(11) NOT NULL DEFAULT 0,
  `total_qty` int(11) NOT NULL DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `keranjang`
--

INSERT INTO `keranjang` (`id_keranjang`, `id_users`, `id_gerai`, `status`, `total_harga`, `total_qty`, `created_at`, `updated_at`) VALUES
(4, 1, 3, 'checkout', 0, 0, '2025-08-26 16:20:01', '2025-08-27 19:53:03'),
(5, 1, 3, 'checkout', 0, 0, '2025-08-27 19:53:34', '2025-08-27 19:59:47'),
(6, 1, 3, 'checkout', 0, 0, '2025-08-27 20:02:41', '2025-08-27 20:03:16'),
(7, 1, 3, 'checkout', 0, 0, '2025-08-27 20:05:08', '2025-08-27 20:08:35'),
(8, 1, 3, 'checkout', 0, 0, '2025-08-27 20:12:11', '2025-08-27 20:24:12'),
(9, 1, 3, 'checkout', 0, 0, '2025-08-27 20:24:55', '2025-08-27 20:25:14'),
(10, 1, 3, 'checkout', 0, 0, '2025-08-27 20:26:04', '2025-08-27 20:26:17'),
(11, 1, 3, 'checkout', 0, 0, '2025-08-27 20:26:40', '2025-08-27 20:27:01'),
(12, 1, 3, 'checkout', 0, 0, '2025-08-27 20:34:10', '2025-08-27 20:37:15'),
(13, 1, 3, 'checkout', 0, 0, '2025-08-27 20:37:33', '2025-08-29 09:51:44'),
(14, 1, 3, 'checkout', 0, 0, '2025-08-29 10:09:14', '2025-08-29 10:09:23'),
(15, 1, 3, 'checkout', 0, 0, '2025-08-29 10:11:26', '2025-08-29 10:11:29'),
(16, 1, 3, 'checkout', 0, 0, '2025-08-29 10:24:09', '2025-08-29 10:24:11'),
(17, 1, 3, 'checkout', 0, 0, '2025-08-29 10:25:53', '2025-08-29 10:25:56'),
(18, 1, 3, 'checkout', 0, 0, '2025-08-29 10:26:51', '2025-08-29 10:26:55'),
(19, 1, 3, 'checkout', 0, 0, '2025-08-29 10:31:54', '2025-08-29 10:31:56'),
(20, 1, 3, 'checkout', 0, 0, '2025-08-29 10:35:06', '2025-08-29 10:35:11'),
(21, 1, 3, 'checkout', 0, 0, '2025-08-29 10:48:21', '2025-08-29 10:48:24'),
(22, 1, 3, 'checkout', 0, 0, '2025-08-29 12:20:51', '2025-08-29 12:20:54'),
(23, 1, 3, 'checkout', 0, 0, '2025-08-29 12:21:02', '2025-08-29 12:21:23'),
(24, 1, 3, 'checkout', 0, 0, '2025-08-29 12:23:17', '2025-08-29 12:23:20'),
(25, 1, 3, 'checkout', 0, 0, '2025-08-29 12:26:00', '2025-08-29 12:26:02'),
(26, 1, 3, 'checkout', 0, 0, '2025-08-29 12:28:05', '2025-08-29 12:28:08'),
(27, 1, 3, 'checkout', 0, 0, '2025-08-29 12:29:31', '2025-08-29 12:29:34'),
(28, 1, 3, 'checkout', 0, 0, '2025-08-29 12:41:12', '2025-08-29 12:41:15'),
(29, 1, 3, 'checkout', 0, 0, '2025-08-29 13:34:18', '2025-08-29 13:34:32'),
(30, 1, 3, 'checkout', 0, 0, '2025-08-29 13:43:27', '2025-08-29 13:43:29'),
(31, 1, 3, 'checkout', 0, 0, '2025-08-29 13:51:48', '2025-08-29 13:51:54'),
(32, 1, 3, 'checkout', 0, 0, '2025-08-29 14:41:28', '2025-08-29 14:41:32'),
(33, 1, 3, 'checkout', 0, 0, '2025-08-29 18:29:01', '2025-08-29 18:43:43'),
(34, 1, 3, 'checkout', 0, 0, '2025-08-29 18:48:20', '2025-08-29 18:48:27'),
(35, 1, 3, 'checkout', 0, 0, '2025-08-29 18:49:10', '2025-08-29 18:49:33'),
(36, 1, 3, 'checkout', 0, 0, '2025-08-29 18:52:08', '2025-08-29 19:03:27'),
(37, 1, 3, 'checkout', 0, 0, '2025-08-29 19:04:04', '2025-08-29 19:04:10'),
(38, 1, 3, 'checkout', 0, 0, '2025-08-29 19:07:44', '2025-08-29 19:07:50'),
(39, 1, 3, 'checkout', 0, 0, '2025-08-29 19:09:44', '2025-08-29 19:09:48'),
(40, 1, 3, 'checkout', 0, 0, '2025-08-29 19:11:39', '2025-08-29 19:11:43'),
(41, 1, 3, 'checkout', 0, 0, '2025-08-29 19:16:25', '2025-08-29 19:16:29'),
(42, 1, 3, 'checkout', 0, 0, '2025-08-29 19:18:37', '2025-08-29 19:18:40'),
(43, 1, 3, 'checkout', 0, 0, '2025-08-29 19:21:29', '2025-08-29 19:21:33'),
(44, 1, 3, 'checkout', 0, 0, '2025-08-29 19:26:32', '2025-08-29 19:26:36'),
(45, 1, 3, 'checkout', 0, 0, '2025-08-29 19:32:44', '2025-08-29 19:34:50'),
(46, 1, 3, 'checkout', 0, 0, '2025-08-29 19:39:09', '2025-08-29 19:39:15'),
(47, 1, 3, 'checkout', 0, 0, '2025-08-29 19:45:22', '2025-08-29 19:45:28'),
(48, 1, 3, 'checkout', 0, 0, '2025-08-29 20:18:07', '2025-08-29 20:18:10'),
(49, 1, 3, 'checkout', 0, 0, '2025-08-29 20:19:46', '2025-08-29 20:19:49'),
(50, 1, 3, 'checkout', 0, 0, '2025-08-29 20:22:18', '2025-08-29 20:22:27'),
(51, 1, 3, 'checkout', 0, 0, '2025-08-29 20:23:50', '2025-08-29 20:23:56'),
(52, 1, 3, 'checkout', 0, 0, '2025-08-30 09:31:26', '2025-08-30 09:31:56'),
(53, 1, 3, 'checkout', 0, 0, '2025-08-30 11:33:52', '2025-08-30 11:34:05'),
(54, 1, 3, 'checkout', 0, 0, '2025-08-30 15:29:29', '2025-09-10 13:38:37'),
(55, 1, 3, 'aktif', 50000, 2, '2025-09-10 13:42:02', '2025-09-10 13:42:06');

-- --------------------------------------------------------

--
-- Table structure for table `keranjang_item`
--

CREATE TABLE `keranjang_item` (
  `id_keranjang_item` int(11) NOT NULL,
  `id_keranjang` int(11) NOT NULL,
  `id_menu` int(11) NOT NULL,
  `qty` int(11) NOT NULL,
  `harga_satuan` int(11) NOT NULL,
  `subtotal` int(11) NOT NULL,
  `note` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `keranjang_item`
--

INSERT INTO `keranjang_item` (`id_keranjang_item`, `id_keranjang`, `id_menu`, `qty`, `harga_satuan`, `subtotal`, `note`, `created_at`, `updated_at`) VALUES
(107, 55, 4, 2, 25000, 50000, NULL, '2025-09-10 13:42:02', '2025-09-10 13:42:06');

-- --------------------------------------------------------

--
-- Table structure for table `keranjang_item_addon`
--

CREATE TABLE `keranjang_item_addon` (
  `id_keranjang_item_addon` int(11) NOT NULL,
  `id_keranjang_item` int(11) NOT NULL,
  `id_addon` int(11) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `menu`
--

CREATE TABLE `menu` (
  `id_menu` int(11) NOT NULL,
  `id_gerai` int(11) NOT NULL,
  `id_etalase` int(11) DEFAULT NULL,
  `nama_menu` varchar(100) NOT NULL,
  `gambar_menu` varchar(255) DEFAULT NULL,
  `deskripsi_menu` text DEFAULT NULL,
  `kategori` enum('makanan','minuman','jajanan') NOT NULL,
  `harga` int(11) NOT NULL,
  `jumlah_stok` int(11) NOT NULL,
  `tersedia` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `menu`
--

INSERT INTO `menu` (`id_menu`, `id_gerai`, `id_etalase`, `nama_menu`, `gambar_menu`, `deskripsi_menu`, `kategori`, `harga`, `jumlah_stok`, `tersedia`, `created_at`, `updated_at`) VALUES
(4, 3, 7, 'Ayam Goreng', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757141293/z8mrha0aqytscmyejm8a.jpg', 'Ayam + Nasi + Lalapan +Sambel', 'makanan', 25000, 18, 1, '2025-08-26 12:00:29', '2025-09-15 15:48:37'),
(7, 3, 5, 'Bakso Kuah', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756542932/xod4yyoeqvphy6zf13rf.jpg', 'Bakso daging sapi', 'makanan', 26000, 28, 1, '2025-08-30 15:35:32', '2025-09-15 14:01:25'),
(9, 5, NULL, 'Cakwe', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756544541/eztvz8peefxgt6bdz7rc.jpg', 'Jajanan Cakwe is 10', 'jajanan', 15000, 10, 1, '2025-08-30 16:02:22', '2025-08-30 16:02:22'),
(10, 3, 19, 'Mie', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756699745/andvjdfnvf0rdg1v0pk3.jpg', 'Mie instan', 'makanan', 5000, 20, 1, '2025-09-01 11:09:06', '2025-09-15 13:52:13'),
(37, 8, 15, 'Ayam Goreng', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756978437/dh5mridcpsc7laey91gk.jpg', 'Ayam+Lalapan+nasi', 'makanan', 19000, 20, 0, '2025-09-04 16:33:56', '2025-09-04 16:41:51'),
(38, 9, 16, 'Bakso', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757046875/sxsco0j9ksfestezqeay.jpg', 'Bakso daging is 5 dengan bihun dan kuah yang segar', 'makanan', 19000, 20, 1, '2025-09-05 11:34:37', '2025-09-05 11:34:37'),
(39, 9, 20, 'Matcha Latte', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757141482/zjankz0woace7kz9yjoe.jpg', 'Hot Matcha Latte', 'minuman', 20000, 10, 1, '2025-09-06 13:51:21', '2025-09-06 13:51:21'),
(40, 10, 21, 'Ayam Sambel Matah', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757218553/dhw1ae9qwblzaerkw2ds.jpg', 'Ayam + Sambel + Nasi', 'makanan', 19000, 10, 1, '2025-09-07 11:15:55', '2025-09-07 11:16:05'),
(41, 10, 22, 'Cakwe', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757218619/taabxzwwy7rbf8dblkfu.jpg', 'Cakwe is 8', 'jajanan', 16000, 5, 1, '2025-09-07 11:17:01', '2025-09-07 11:17:03'),
(42, 10, 24, 'Seblak', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757220451/o1je7mst0kladk34cfqj.jpg', 'Seblak is kerupuk, sayur, telur, sosis, bakso', 'makanan', 19000, 20, 1, '2025-09-07 11:47:32', '2025-09-07 11:47:32'),
(43, 11, 26, 'Roti Abon', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757221679/saornpyzg5xxhyg7ddln.jpg', 'Roti dengan toping abon', 'makanan', 8000, 10, 1, '2025-09-07 12:08:00', '2025-09-07 12:08:00'),
(44, 12, 27, 'Bakso', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757222380/vuu2ifrvi50ootlbblzm.jpg', 'Bakso is 5', 'makanan', 15000, 10, 1, '2025-09-07 12:19:41', '2025-09-07 12:19:41'),
(45, 13, 28, 'Bakso', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757302896/wajwd2sgq1o5a5omyfe3.jpg', 'Bakso daging sapi is 4 dengan bihun dan sayur', 'makanan', 18000, 20, 1, '2025-09-08 10:41:36', '2025-09-08 10:41:36'),
(46, 3, 1, 'Seblak Ceker', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757303090/dvrv8o8tv8h1knrd7bap.jpg', 'Seblak dengan toping kerupuk, sayur, dan sosis', 'makanan', 20000, 20, 1, '2025-09-08 10:44:50', '2025-09-08 10:44:50'),
(47, 14, 29, 'Ayam Goreng', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757314787/qtx53uanqogwibh8ey0u.jpg', 'Ayam + Lalapan + Nasi', 'makanan', 25000, 10, 1, '2025-09-08 13:59:47', '2025-09-08 13:59:47');

-- --------------------------------------------------------

--
-- Table structure for table `menu_addon`
--

CREATE TABLE `menu_addon` (
  `id_menu_addon` int(11) NOT NULL,
  `id_menu` int(11) NOT NULL,
  `id_addon` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `menu_addon`
--

INSERT INTO `menu_addon` (`id_menu_addon`, `id_menu`, `id_addon`) VALUES
(45, 37, 17),
(46, 38, 18),
(55, 39, 19),
(57, 4, 7),
(58, 4, 15),
(59, 40, 21),
(60, 43, 23),
(61, 45, 24),
(62, 46, 7),
(63, 47, 25),
(64, 10, 7),
(67, 7, 9),
(68, 7, 7);

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `id` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `otp` varchar(6) NOT NULL,
  `expired_at` datetime NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `password_resets`
--

INSERT INTO `password_resets` (`id`, `email`, `otp`, `expired_at`, `created_at`) VALUES
(5, 'raihanadeprnm@gmail.com', '969287', '2025-08-20 12:35:31', '2025-08-20 12:25:31');

-- --------------------------------------------------------

--
-- Table structure for table `penjual_info`
--

CREATE TABLE `penjual_info` (
  `id_penjual_info` int(11) NOT NULL,
  `id_users` int(11) NOT NULL,
  `id_gerai` int(11) NOT NULL,
  `no_telepon_penjual` varchar(30) DEFAULT NULL,
  `nik` varchar(30) NOT NULL,
  `tempat_lahir` varchar(100) NOT NULL,
  `tanggal_lahir` date NOT NULL,
  `jenis_kelamin` enum('laki-laki','perempuan') NOT NULL,
  `foto_ktp_path` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `penjual_info`
--

INSERT INTO `penjual_info` (`id_penjual_info`, `id_users`, `id_gerai`, `no_telepon_penjual`, `nik`, `tempat_lahir`, `tanggal_lahir`, `jenis_kelamin`, `foto_ktp_path`, `created_at`, `updated_at`) VALUES
(1, 1, 1, '098675432', '09876542345', 'tangerang', '2015-08-06', 'perempuan', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756554812/rrquxbrrfrtsglaicgym.jpg', '2025-08-23 11:32:40', '2025-09-01 11:41:57'),
(2, 2, 2, '098675432', '0987654234544', 'tangerang', '2015-08-06', 'perempuan', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756554812/rrquxbrrfrtsglaicgym.jpg', '2025-08-23 11:32:40', '2025-09-01 11:41:57'),
(3, 5, 3, '098675432', '09876549000', 'tangerang', '2015-08-06', 'perempuan', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756554812/rrquxbrrfrtsglaicgym.jpg', '2025-08-23 11:32:40', '2025-09-01 11:41:57'),
(5, 12, 5, '098675432', '098765490001', 'tangerang', '2015-08-06', 'perempuan', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756554812/rrquxbrrfrtsglaicgym.jpg', '2025-08-23 11:32:40', '2025-09-01 11:41:57'),
(7, 14, 8, '08272938', '36031267050909', 'Bogor', '2005-01-12', 'laki-laki', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756969127/dzvudvn13mxwtfpjimwc.jpg', '2025-09-04 13:57:51', '2025-09-04 15:13:05'),
(8, 15, 9, '089686896837', '3603126703950010', 'Tangerang', '2005-01-10', 'perempuan', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757045467/eztldaf6ofwn6wjqu8x8.jpg', '2025-09-04 17:19:34', '2025-09-05 11:29:02'),
(9, 16, 10, '0875672819', '37610383993031', 'Kuningan', '2000-01-20', 'perempuan', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757168282/oq7wf0sahj7jyqjoeiik.jpg', '2025-09-06 21:16:01', '2025-09-07 11:08:35'),
(10, 17, 11, '0862789432', '122334332454234', 'Banyuwangi', '2004-10-15', 'perempuan', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757221499/o3ae2exll0hlxgu0ybbe.jpg', '2025-09-07 12:05:00', '2025-09-07 12:05:33'),
(11, 9, 12, '081378237138', '02983435457', 'Banywuangi', '2004-01-23', 'perempuan', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757222222/wq8zjk5wlb1tcmtiatgd.jpg', '2025-09-07 12:17:03', '2025-09-07 12:17:03'),
(12, 18, 13, '08967283746', '360312673748221', 'Depok', '1994-01-21', 'laki-laki', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757302722/bzqnd01dswgwa47m3knz.jpg', '2025-09-08 10:25:58', '2025-09-08 10:38:42'),
(13, 19, 14, '92863552892', '097252791289738', 'Depok', '1961-01-01', 'perempuan', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757314379/fxokyg2fsccpqkxlgwfq.jpg', '2025-09-08 13:52:26', '2025-09-08 13:55:56'),
(15, 23, 16, '0867398458', '36923849592934', 'Tulungagung', '2005-01-10', 'laki-laki', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757926624/t86shgpzmrkawviruyzo.jpg', '2025-09-15 15:57:05', '2025-09-15 15:57:05');

-- --------------------------------------------------------

--
-- Table structure for table `transaksi`
--

CREATE TABLE `transaksi` (
  `id_transaksi` int(11) NOT NULL,
  `booking_id` varchar(50) NOT NULL,
  `id_users` int(11) NOT NULL,
  `id_gerai` int(11) NOT NULL,
  `id_alamat` int(11) DEFAULT NULL,
  `STATUS` enum('konfirmasi_ketersediaan','konfirmasi_pembayaran','disiapkan','diantar','pickup','selesai','dibatalkan') DEFAULT 'konfirmasi_ketersediaan',
  `metode_pembayaran` enum('qris','cash') NOT NULL,
  `total_harga` int(11) NOT NULL,
  `biaya_pengantaran` int(11) DEFAULT 5000,
  `jenis_pengantaran` enum('pengantaran','pickup') NOT NULL,
  `catatan_pembatalan` text DEFAULT NULL,
  `bukti_pembayaran` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transaksi`
--

INSERT INTO `transaksi` (`id_transaksi`, `booking_id`, `id_users`, `id_gerai`, `id_alamat`, `STATUS`, `metode_pembayaran`, `total_harga`, `biaya_pengantaran`, `jenis_pengantaran`, `catatan_pembatalan`, `bukti_pembayaran`, `created_at`, `updated_at`) VALUES
(49, 'F-9C347E', 1, 3, 4, 'konfirmasi_pembayaran', 'qris', 44000, 5000, 'pengantaran', NULL, '', '2025-08-29 20:19:49', '2025-09-06 16:28:52'),
(50, 'F-6D9BA7', 1, 3, NULL, 'selesai', 'qris', 39000, 0, 'pickup', NULL, '', '2025-08-29 20:22:27', '2025-08-29 20:23:33'),
(51, 'F-315329', 1, 3, 3, 'dibatalkan', 'qris', 36000, 5000, 'pengantaran', 'Dibatalkan Penjual Karena Pembayaran Tidak Sesuai', '', '2025-08-29 20:23:56', '2025-08-29 20:24:42'),
(52, 'F-16CFB8', 1, 3, 4, 'selesai', 'qris', 36000, 5000, 'pengantaran', NULL, '', '2025-08-30 09:31:56', '2025-08-30 09:54:24'),
(53, 'F-F13299', 1, 3, NULL, 'selesai', 'qris', 39000, 0, 'pickup', NULL, '', '2025-08-30 11:34:05', '2025-08-30 12:34:01'),
(56, 'F-F13233', 10, 3, 4, 'selesai', 'cash', 39000, 5000, 'pengantaran', NULL, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757156856/bukti_pembayaran_cash/cwhayvwhwh1f2puy4456.jpg', '2025-09-01 11:34:05', '2025-09-06 18:07:35'),
(57, 'F-F13236', 3, 3, 4, 'selesai', 'qris', 39000, 5000, 'pengantaran', NULL, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756554812/rrquxbrrfrtsglaicgym.jpg', '2025-09-01 11:34:05', '2025-09-06 16:29:26'),
(58, 'F-F13238', 4, 3, 4, 'selesai', 'cash', 39000, 5000, 'pengantaran', NULL, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756710331/bukti_pembayaran_cash/m8dkcmopbk2hmu9kprml.jpg', '2025-09-01 11:34:05', '2025-09-01 14:05:32'),
(59, 'F-F13239', 9, 3, 4, 'dibatalkan', 'qris', 39000, 5000, 'pengantaran', 'Menu habis', '', '2025-09-01 11:34:05', '2025-09-01 14:03:13'),
(60, 'F-F13212', 9, 9, 4, 'selesai', 'cash', 39000, 5000, 'pengantaran', '', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757047987/bukti_pembayaran_cash/hoh8u5qzybxad3azmlnc.png', '2025-09-05 11:34:05', '2025-09-05 11:53:08'),
(61, 'F-F13219', 9, 3, 4, 'selesai', 'qris', 39000, 5000, 'pengantaran', '', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756989074/zyy8d45gdn6edguezsts.png', '2025-09-06 11:34:05', '2025-09-06 17:42:21'),
(62, 'F-F13280', 9, 3, 4, 'selesai', 'cash', 39000, 5000, 'pengantaran', '', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757311148/bukti_pembayaran_cash/ftsqufzwx0mi8hynwjv3.png', '2025-09-06 11:34:05', '2025-09-08 12:59:07'),
(63, 'F-1B42AF', 1, 3, 4, 'disiapkan', 'qris', 36000, 5000, 'pengantaran', NULL, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757486484/bukti_pembayaran/isbndtf8e2drzknbbkvy.jpg', '2025-09-10 13:38:37', '2025-09-10 13:41:37'),
(65, 'F-1B42WF', 1, 3, 4, 'selesai', 'qris', 36000, 5000, 'pengantaran', NULL, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757486484/bukti_pembayaran/isbndtf8e2drzknbbkvy.jpg', '2025-09-15 13:38:37', '2025-09-15 15:46:39'),
(67, 'F-1B42WQ', 7, 3, 4, 'dibatalkan', 'qris', 36000, 5000, 'pickup', 'Toko tutup', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1757486484/bukti_pembayaran/isbndtf8e2drzknbbkvy.jpg', '2025-09-15 13:38:37', '2025-09-15 15:47:56');

-- --------------------------------------------------------

--
-- Table structure for table `transaksi_item`
--

CREATE TABLE `transaksi_item` (
  `id_transaksi_item` int(11) NOT NULL,
  `id_transaksi` int(11) NOT NULL,
  `id_menu` int(11) NOT NULL,
  `jumlah` int(11) NOT NULL,
  `harga_satuan` int(11) NOT NULL,
  `subtotal` int(11) NOT NULL,
  `note` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transaksi_item`
--

INSERT INTO `transaksi_item` (`id_transaksi_item`, `id_transaksi`, `id_menu`, `jumlah`, `harga_satuan`, `subtotal`, `note`) VALUES
(50, 49, 4, 1, 39000, 39000, 'pedas'),
(51, 50, 4, 1, 39000, 39000, ''),
(52, 51, 4, 1, 31000, 31000, ''),
(53, 52, 4, 1, 31000, 31000, ''),
(54, 53, 4, 1, 39000, 39000, ''),
(56, 56, 4, 1, 39000, 39000, ''),
(57, 57, 7, 2, 25000, 50000, 'Extra Sambel'),
(58, 58, 4, 1, 39000, 39000, 'Bagian dada'),
(59, 59, 4, 1, 39000, 39000, ''),
(60, 60, 4, 1, 39000, 39000, ''),
(61, 61, 4, 1, 39000, 39000, ''),
(62, 62, 4, 1, 39000, 39000, ''),
(63, 63, 4, 1, 31000, 31000, ''),
(64, 65, 4, 1, 31000, 31000, 'Extra kremes'),
(65, 67, 4, 1, 31000, 31000, 'Extra kremes');

-- --------------------------------------------------------

--
-- Table structure for table `transaksi_item_addon`
--

CREATE TABLE `transaksi_item_addon` (
  `id_transaksi_item_addon` int(11) NOT NULL,
  `id_transaksi_item` int(11) NOT NULL,
  `id_addon` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transaksi_item_addon`
--

INSERT INTO `transaksi_item_addon` (`id_transaksi_item_addon`, `id_transaksi_item`, `id_addon`) VALUES
(44, 50, 7),
(45, 50, 15),
(46, 51, 7),
(47, 51, 15),
(48, 52, 7),
(49, 53, 7),
(50, 54, 7),
(51, 54, 15),
(53, 57, 9),
(54, 63, 7);

-- --------------------------------------------------------

--
-- Table structure for table `ulasan`
--

CREATE TABLE `ulasan` (
  `id_ulasan` int(11) NOT NULL,
  `id_transaksi` int(11) NOT NULL,
  `id_users` int(11) NOT NULL,
  `rating` int(11) NOT NULL CHECK (`rating` between 1 and 5),
  `komentar` text DEFAULT NULL,
  `is_anonymous` tinyint(1) NOT NULL DEFAULT 0,
  `balasan` varchar(200) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `ulasan`
--

INSERT INTO `ulasan` (`id_ulasan`, `id_transaksi`, `id_users`, `rating`, `komentar`, `is_anonymous`, `balasan`, `created_at`) VALUES
(3, 52, 1, 5, '', 1, 'Terima kasih ka', '2025-08-30 11:16:46'),
(4, 50, 1, 4, 'Makanannya enak', 0, 'Makasih ka jangan lupa beli lagi ya', '2025-08-30 11:31:41'),
(5, 53, 1, 3, 'Kurang Sambel', 0, 'Maaf kak', '2025-08-30 12:34:17'),
(13, 60, 9, 4, 'Mantap, Enak sekali ayamnya besar', 0, 'Terima kasih ka', '2025-08-30 12:34:17');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id_users` int(11) NOT NULL,
  `nama_lengkap` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `no_hp` varchar(30) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('0','1','2') NOT NULL,
  `photo_path` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `step1` tinyint(1) NOT NULL,
  `step2` tinyint(1) NOT NULL,
  `step3` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id_users`, `nama_lengkap`, `username`, `email`, `no_hp`, `password_hash`, `role`, `photo_path`, `created_at`, `updated_at`, `step1`, `step2`, `step3`) VALUES
(1, 'Noeni Indah', 'noeniis', 'noeni@gmail.com', '0868373984', '$2y$10$Ypn7F39UBtO4peSt2GPc4.ZKhuDVde31qxgsf4VI.Zzu3mKBSoezO', '0', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756292863/df2watlencv0kfjzwr6n.jpg', '2025-08-20 08:46:39', '2025-08-28 08:12:45', 0, 0, 0),
(2, 'raihan ade', 'raihan', 'raihan@gmail.com', '0896374378', '$2y$10$0nqBOzEiOOBfqmCCUEREceSOlRZrmk/J1A/Pr40KTvGY9E1ATOFiK', '1', NULL, '2025-08-20 08:47:38', '2025-08-28 07:31:00', 0, 0, 0),
(3, 'Noeni Indh', 'noeniindh', 'noeniindahs27@gmail.com', '085719832740', '$2y$10$XQ9KWkzRj93mCXrBuGjJrOormPrL7CSXfzHGoouFHNKiQIDhq5yCu', '0', NULL, '2025-08-20 08:56:09', '2025-08-28 07:31:00', 0, 0, 0),
(4, 'Raihan Ade Purnomo', 'raihanadep', 'raihanadeprnm@gmail.com', '081385321390', '$2y$10$Kul7xV7qwqX.ywMgLd6X0O5QlfQF/Pz1SYb6SJtiPtywa0fc/5h2K', '0', NULL, '2025-08-20 11:06:08', '2025-08-28 07:31:00', 0, 0, 0),
(5, 'Sila A', 'sila', 'noeniindhs27@gmail.com', '0857199209', '$2y$10$dgBJ4CXc6ci7EZ.wyfxZhuWf4h474RCBgkpTTkXgpPKYAzAAKG4/G', '1', NULL, '2025-08-21 07:55:43', '2025-09-05 12:30:55', 1, 1, 1),
(7, 'azriel', 'azriel', 'azriel@gmail.com', '08138526372', '$2y$10$rFKakE92te.GsMN5yl/3ruX.WUd0AUET3iWI8BqyxXlGOV/3lN0Zq', '0', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-08-27 18:24:35', '2025-08-28 07:31:00', 0, 0, 0),
(8, 'Budi', 'budi', 'budi@gmail.com', '09893424835', '$2y$10$FGc4fcDrKG81ub0AM33hD.NDevoqxhoHubGrllfnO5TJYaE0j.Rdm', '0', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-08-28 07:36:01', '2025-08-28 07:36:01', 0, 0, 0),
(9, 'ayu', 'ayu', 'ayu@gmail.com', '081378237138', '$2y$10$8eJeX6VisRYEV7IWpr.80Olz0n.qWIS.BhtlEDdg8VWWpU4BpB28O', '1', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-08-28 07:39:08', '2025-09-07 12:19:41', 1, 1, 1),
(10, 'ida', 'ida', 'ida@gmail.com', '0813628283', '$2y$10$aM1iS5gFom60tvN1tzqBKeNMzOGTw05XLtClHxwRk0yAG.5NqZGz.', '0', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-08-28 07:40:21', '2025-08-28 07:40:21', 0, 0, 0),
(12, 'Farah Aini', 'fara', 'faraini@gmail.com', '0896983827', '$2y$10$lrkHiLz/zG24Rr5WdWbsreFl2MeUP0OYGCvoeLzomF.wVYHBIUxMS', '1', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-08-30 15:56:50', '2025-08-30 15:57:10', 1, 1, 1),
(13, 'Laura', 'lau', 'lau@gmail.com', '08574838585', '$2y$10$fpd.afdGz3rW04ADR/3C8uKIQI5O.GL4i8k3mrR/yvXbQOlQLjByi', '1', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-09-01 09:56:55', '2025-09-01 11:24:03', 0, 1, 0),
(14, 'Ihsan', 'ihsan', 'ihsan@gmail.com', '08272938', '$2y$10$0uJ7o/IiSigugRPfaid0LOjG2GLfuiFWH.2WGuxw8TCqyArKJ6p1u', '1', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-09-04 12:11:29', '2025-09-04 16:33:57', 1, 1, 1),
(15, 'Nina Qurrotul', 'nina', 'ninaqur@gmail.com', '089686896837', '$2y$10$HCrb24Vuo4H4BljVa5L3WOwzkeOvw7CW9ELmIqu5O/FmXK.IeL4nG', '1', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-09-04 16:59:13', '2025-09-06 09:43:17', 1, 1, 1),
(16, 'Laila Nurjannah', 'laila', 'lailanurj@gmail.com', '0875672819', '$2y$10$d6ER8WDkYu1S/kbT2ACV4e65QxwHwtP49z8DreRzGajssi3ML2xBK', '1', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-09-06 20:33:28', '2025-09-07 11:47:32', 1, 1, 1),
(17, 'Kinanti Arum', 'kinan', 'kinanti@gmail.com', '0862789432', '$2y$10$jJ1NzDMunfkEylXzZ7ImMO3a2H.A.eSn8x5qghiKEiU1unfz7VdPy', '1', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-09-07 11:51:25', '2025-09-07 12:08:00', 1, 1, 1),
(18, 'Hasan Junaidi', 'Hasan', 'hasanj@gmail.com', '08967283746', '$2y$10$Ew/pDQkUSS8Yich0icd4iexrXUUFy2fWMkub/4LJtJVPtW5snf012', '1', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-09-08 10:23:37', '2025-09-08 10:42:41', 1, 1, 1),
(19, 'Laura', 'laura', 'laura@gmail.com', '92863552892', '$2y$10$AJryKWJ/ZC/d8X8s5r5D3.Twf0Gx4.ECJu6SrSb9jXx7CBIaoEcuW', '1', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-09-08 13:50:16', '2025-09-08 13:59:47', 1, 1, 1),
(20, 'koperasi', 'koperasi', 'koperasi@gmail.com', '0862849474', '$2y$10$46XE.xXfmQGft7GQ55l8suP0meHChbUFaHtjVVYVxK8gc6snNMIiq', '2', NULL, '2025-09-11 13:08:12', '2025-09-11 13:08:12', 0, 0, 0),
(21, 'Julia Rahma', 'Julia', 'juliarahma@gmail.com', '0872673847', '$2y$10$A/JSWwkJeGEy0/AZGQw70OHlLDZdTb.EZKguAbZC1OMB6UKGkabDO', '1', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-09-12 20:48:26', '2025-09-12 20:48:26', 0, 0, 0),
(23, 'Heriyadi', 'Heri', 'heriyadi@gmail.com', '0867398458', '$2y$10$9eKARM5HM04a605gctNH8u3RaN0VYE9t/aQDYnF/4.yJgHZAX/nh.', '1', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-09-15 15:55:49', '2025-09-15 16:06:56', 0, 0, 0);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `addon`
--
ALTER TABLE `addon`
  ADD PRIMARY KEY (`id_addon`),
  ADD KEY `id_gerai` (`id_gerai`);

--
-- Indexes for table `alamat_pengantaran`
--
ALTER TABLE `alamat_pengantaran`
  ADD PRIMARY KEY (`id_alamat`),
  ADD KEY `id_users` (`id_users`);

--
-- Indexes for table `etalase`
--
ALTER TABLE `etalase`
  ADD PRIMARY KEY (`id_etalase`),
  ADD UNIQUE KEY `id_gerai` (`id_gerai`,`nama_etalase`);

--
-- Indexes for table `favorite`
--
ALTER TABLE `favorite`
  ADD PRIMARY KEY (`id_favorite`),
  ADD UNIQUE KEY `id_users` (`id_users`,`id_menu`),
  ADD KEY `id_menu` (`id_menu`);

--
-- Indexes for table `gerai`
--
ALTER TABLE `gerai`
  ADD PRIMARY KEY (`id_gerai`),
  ADD UNIQUE KEY `id_users` (`id_users`);

--
-- Indexes for table `gerai_profil`
--
ALTER TABLE `gerai_profil`
  ADD PRIMARY KEY (`id_gerai_profil`),
  ADD UNIQUE KEY `id_gerai` (`id_gerai`);

--
-- Indexes for table `keranjang`
--
ALTER TABLE `keranjang`
  ADD PRIMARY KEY (`id_keranjang`),
  ADD KEY `fk_keranjang_users` (`id_users`),
  ADD KEY `fk_keranjang_gerai` (`id_gerai`);

--
-- Indexes for table `keranjang_item`
--
ALTER TABLE `keranjang_item`
  ADD PRIMARY KEY (`id_keranjang_item`),
  ADD KEY `idx_keranjang_item_keranjang` (`id_keranjang`),
  ADD KEY `idx_keranjang_item_menu` (`id_menu`);

--
-- Indexes for table `keranjang_item_addon`
--
ALTER TABLE `keranjang_item_addon`
  ADD PRIMARY KEY (`id_keranjang_item_addon`),
  ADD KEY `idx_kia_item` (`id_keranjang_item`),
  ADD KEY `idx_kia_addon` (`id_addon`);

--
-- Indexes for table `menu`
--
ALTER TABLE `menu`
  ADD PRIMARY KEY (`id_menu`),
  ADD KEY `id_gerai` (`id_gerai`),
  ADD KEY `id_etalase` (`id_etalase`);

--
-- Indexes for table `menu_addon`
--
ALTER TABLE `menu_addon`
  ADD PRIMARY KEY (`id_menu_addon`),
  ADD KEY `id_menu` (`id_menu`),
  ADD KEY `id_addon` (`id_addon`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `penjual_info`
--
ALTER TABLE `penjual_info`
  ADD PRIMARY KEY (`id_penjual_info`),
  ADD UNIQUE KEY `id_users` (`id_users`),
  ADD UNIQUE KEY `id_gerai` (`id_gerai`),
  ADD UNIQUE KEY `nik` (`nik`);

--
-- Indexes for table `transaksi`
--
ALTER TABLE `transaksi`
  ADD PRIMARY KEY (`id_transaksi`),
  ADD UNIQUE KEY `booking_id` (`booking_id`),
  ADD KEY `id_users` (`id_users`),
  ADD KEY `id_gerai` (`id_gerai`),
  ADD KEY `idx_transaksi_id_alamat` (`id_alamat`);

--
-- Indexes for table `transaksi_item`
--
ALTER TABLE `transaksi_item`
  ADD PRIMARY KEY (`id_transaksi_item`),
  ADD KEY `id_transaksi` (`id_transaksi`),
  ADD KEY `id_menu` (`id_menu`);

--
-- Indexes for table `transaksi_item_addon`
--
ALTER TABLE `transaksi_item_addon`
  ADD PRIMARY KEY (`id_transaksi_item_addon`),
  ADD KEY `id_transaksi_item` (`id_transaksi_item`),
  ADD KEY `id_addon` (`id_addon`);

--
-- Indexes for table `ulasan`
--
ALTER TABLE `ulasan`
  ADD PRIMARY KEY (`id_ulasan`),
  ADD UNIQUE KEY `id_transaksi` (`id_transaksi`),
  ADD KEY `id_users` (`id_users`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id_users`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `addon`
--
ALTER TABLE `addon`
  MODIFY `id_addon` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `alamat_pengantaran`
--
ALTER TABLE `alamat_pengantaran`
  MODIFY `id_alamat` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `etalase`
--
ALTER TABLE `etalase`
  MODIFY `id_etalase` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `favorite`
--
ALTER TABLE `favorite`
  MODIFY `id_favorite` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `gerai`
--
ALTER TABLE `gerai`
  MODIFY `id_gerai` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `gerai_profil`
--
ALTER TABLE `gerai_profil`
  MODIFY `id_gerai_profil` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT for table `keranjang`
--
ALTER TABLE `keranjang`
  MODIFY `id_keranjang` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=56;

--
-- AUTO_INCREMENT for table `keranjang_item`
--
ALTER TABLE `keranjang_item`
  MODIFY `id_keranjang_item` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=108;

--
-- AUTO_INCREMENT for table `keranjang_item_addon`
--
ALTER TABLE `keranjang_item_addon`
  MODIFY `id_keranjang_item_addon` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=155;

--
-- AUTO_INCREMENT for table `menu`
--
ALTER TABLE `menu`
  MODIFY `id_menu` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;

--
-- AUTO_INCREMENT for table `menu_addon`
--
ALTER TABLE `menu_addon`
  MODIFY `id_menu_addon` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=70;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `penjual_info`
--
ALTER TABLE `penjual_info`
  MODIFY `id_penjual_info` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `transaksi`
--
ALTER TABLE `transaksi`
  MODIFY `id_transaksi` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=68;

--
-- AUTO_INCREMENT for table `transaksi_item`
--
ALTER TABLE `transaksi_item`
  MODIFY `id_transaksi_item` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=66;

--
-- AUTO_INCREMENT for table `transaksi_item_addon`
--
ALTER TABLE `transaksi_item_addon`
  MODIFY `id_transaksi_item_addon` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

--
-- AUTO_INCREMENT for table `ulasan`
--
ALTER TABLE `ulasan`
  MODIFY `id_ulasan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id_users` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `addon`
--
ALTER TABLE `addon`
  ADD CONSTRAINT `addon_ibfk_1` FOREIGN KEY (`id_gerai`) REFERENCES `gerai` (`id_gerai`);

--
-- Constraints for table `alamat_pengantaran`
--
ALTER TABLE `alamat_pengantaran`
  ADD CONSTRAINT `alamat_pengantaran_ibfk_1` FOREIGN KEY (`id_users`) REFERENCES `users` (`id_users`);

--
-- Constraints for table `etalase`
--
ALTER TABLE `etalase`
  ADD CONSTRAINT `etalase_ibfk_1` FOREIGN KEY (`id_gerai`) REFERENCES `gerai` (`id_gerai`);

--
-- Constraints for table `favorite`
--
ALTER TABLE `favorite`
  ADD CONSTRAINT `favorite_ibfk_1` FOREIGN KEY (`id_users`) REFERENCES `users` (`id_users`),
  ADD CONSTRAINT `favorite_ibfk_2` FOREIGN KEY (`id_menu`) REFERENCES `menu` (`id_menu`);

--
-- Constraints for table `gerai`
--
ALTER TABLE `gerai`
  ADD CONSTRAINT `gerai_ibfk_1` FOREIGN KEY (`id_users`) REFERENCES `users` (`id_users`);

--
-- Constraints for table `gerai_profil`
--
ALTER TABLE `gerai_profil`
  ADD CONSTRAINT `gerai_profil_ibfk_1` FOREIGN KEY (`id_gerai`) REFERENCES `gerai` (`id_gerai`);

--
-- Constraints for table `keranjang`
--
ALTER TABLE `keranjang`
  ADD CONSTRAINT `fk_keranjang_gerai` FOREIGN KEY (`id_gerai`) REFERENCES `gerai` (`id_gerai`),
  ADD CONSTRAINT `fk_keranjang_users` FOREIGN KEY (`id_users`) REFERENCES `users` (`id_users`);

--
-- Constraints for table `keranjang_item`
--
ALTER TABLE `keranjang_item`
  ADD CONSTRAINT `fk_item_keranjang` FOREIGN KEY (`id_keranjang`) REFERENCES `keranjang` (`id_keranjang`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_item_menu` FOREIGN KEY (`id_menu`) REFERENCES `menu` (`id_menu`);

--
-- Constraints for table `keranjang_item_addon`
--
ALTER TABLE `keranjang_item_addon`
  ADD CONSTRAINT `fk_kia_addon` FOREIGN KEY (`id_addon`) REFERENCES `addon` (`id_addon`),
  ADD CONSTRAINT `fk_kia_item` FOREIGN KEY (`id_keranjang_item`) REFERENCES `keranjang_item` (`id_keranjang_item`) ON DELETE CASCADE;

--
-- Constraints for table `menu`
--
ALTER TABLE `menu`
  ADD CONSTRAINT `menu_ibfk_1` FOREIGN KEY (`id_gerai`) REFERENCES `gerai` (`id_gerai`),
  ADD CONSTRAINT `menu_ibfk_2` FOREIGN KEY (`id_etalase`) REFERENCES `etalase` (`id_etalase`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `menu_addon`
--
ALTER TABLE `menu_addon`
  ADD CONSTRAINT `menu_addon_ibfk_1` FOREIGN KEY (`id_menu`) REFERENCES `menu` (`id_menu`),
  ADD CONSTRAINT `menu_addon_ibfk_2` FOREIGN KEY (`id_addon`) REFERENCES `addon` (`id_addon`);

--
-- Constraints for table `penjual_info`
--
ALTER TABLE `penjual_info`
  ADD CONSTRAINT `penjual_info_ibfk_1` FOREIGN KEY (`id_users`) REFERENCES `users` (`id_users`),
  ADD CONSTRAINT `penjual_info_ibfk_2` FOREIGN KEY (`id_gerai`) REFERENCES `gerai` (`id_gerai`);

--
-- Constraints for table `transaksi`
--
ALTER TABLE `transaksi`
  ADD CONSTRAINT `fk_transaksi_alamat` FOREIGN KEY (`id_alamat`) REFERENCES `alamat_pengantaran` (`id_alamat`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `transaksi_ibfk_1` FOREIGN KEY (`id_users`) REFERENCES `users` (`id_users`),
  ADD CONSTRAINT `transaksi_ibfk_2` FOREIGN KEY (`id_gerai`) REFERENCES `gerai` (`id_gerai`);

--
-- Constraints for table `transaksi_item`
--
ALTER TABLE `transaksi_item`
  ADD CONSTRAINT `transaksi_item_ibfk_1` FOREIGN KEY (`id_transaksi`) REFERENCES `transaksi` (`id_transaksi`),
  ADD CONSTRAINT `transaksi_item_ibfk_2` FOREIGN KEY (`id_menu`) REFERENCES `menu` (`id_menu`);

--
-- Constraints for table `transaksi_item_addon`
--
ALTER TABLE `transaksi_item_addon`
  ADD CONSTRAINT `transaksi_item_addon_ibfk_1` FOREIGN KEY (`id_transaksi_item`) REFERENCES `transaksi_item` (`id_transaksi_item`),
  ADD CONSTRAINT `transaksi_item_addon_ibfk_2` FOREIGN KEY (`id_addon`) REFERENCES `addon` (`id_addon`);

--
-- Constraints for table `ulasan`
--
ALTER TABLE `ulasan`
  ADD CONSTRAINT `ulasan_ibfk_1` FOREIGN KEY (`id_transaksi`) REFERENCES `transaksi` (`id_transaksi`),
  ADD CONSTRAINT `ulasan_ibfk_2` FOREIGN KEY (`id_users`) REFERENCES `users` (`id_users`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
