-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 29, 2025 at 03:25 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

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
(7, 3, 'puding', 6000, 'puding rasa cokelat', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1755961599/br5sodzx3hczoezcqm96.jpg', '2025-08-23 22:06:38', 4, 1),
(9, 3, 'Minuman green tea', 7000, 'minuman green tea', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756007739/bzvadm7wiuqch8vwo3hb.jpg', '2025-08-24 10:55:38', 15, 1),
(14, 3, 'Susu kotak pisang', 6000, 'susu kotak rasa pisang', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756191072/t0ezo6dfcfjqrw2rwikz.jpg', '2025-08-26 13:51:13', 15, 1),
(15, 3, 'Roti Abon', 8000, 'Roti Abon', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756193435/upwwnr9ayz29saosbhho.jpg', '2025-08-26 13:57:48', 4, 1);

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
(7, 3, 'Makanan', '2025-08-26 13:13:27');

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
(3, 5, 'Waroenk Sila', 123.0000000, 123.0000000, 'JL. Maju 10', '0862528293', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/qris-default_lr9x0g.jpg', 'approved', 0, '2025-08-20 11:28:09', '2025-08-26 15:20:40', '');

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
(3, 3, 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756267907/e8ffefeogzdtmikz6nk1.jpg', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756176430/listing-default_srebux.png', 'Ayam, Camilan, Minuman', 'Senin,Selasa,Rabu,Kamis,Jumat', '08:30:00', '05:30:00', '2025-08-23 11:31:51', '2025-08-27 11:16:07');

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
(51, 1, 3, 'checkout', 0, 0, '2025-08-29 20:23:50', '2025-08-29 20:23:56');

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
(4, 3, 7, 'Ayam', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756193397/xppnsoscao0jbph3be2a.jpg', 'Ayam + Nasi + Lalapan +Sambel', 'makanan', 25000, 10, 1, '2025-08-26 12:00:29', '2025-08-26 15:12:59');

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
(26, 4, 7),
(27, 4, 15);

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
(1, 1, 1, '098675432', '09876542345', 'tangerang', '2015-08-06', 'perempuan', '1sdfghj', '2025-08-23 11:32:40', '2025-08-23 11:32:40'),
(2, 2, 2, '098675432', '0987654234544', 'tangerang', '2015-08-06', 'perempuan', '1sdfghj', '2025-08-23 11:32:40', '2025-08-23 11:32:40'),
(3, 5, 3, '098675432', '09876549000', 'tangerang', '2015-08-06', 'perempuan', '1sdfghjer', '2025-08-23 11:32:40', '2025-08-23 11:32:40');

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
(49, 'F-9C347E', 1, 3, 4, 'konfirmasi_ketersediaan', 'qris', 44000, 5000, 'pengantaran', NULL, '', '2025-08-29 20:19:49', '2025-08-29 20:19:49'),
(50, 'F-6D9BA7', 1, 3, NULL, 'selesai', 'qris', 39000, 0, 'pickup', NULL, '', '2025-08-29 20:22:27', '2025-08-29 20:23:33'),
(51, 'F-315329', 1, 3, 3, 'dibatalkan', 'qris', 36000, 5000, 'pengantaran', 'Dibatalkan Penjual Karena Pembayaran Tidak Sesuai', '', '2025-08-29 20:23:56', '2025-08-29 20:24:42');

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
(52, 51, 4, 1, 31000, 31000, '');

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
(48, 52, 7);

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
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
(5, 'Sila A', 'sila', 'noeniindahsulistiyani@gmail.com', '08571992783', '$2y$10$4.HpLPSVqRmbFzHKQ7qlieSNYMChEl8Ym0XPVuOXFqxAaX775XNqm', '1', NULL, '2025-08-21 07:55:43', '2025-08-28 07:31:00', 1, 1, 1),
(7, 'azriel', 'azriel', 'azriel@gmail.com', '08138526372', '$2y$10$rFKakE92te.GsMN5yl/3ruX.WUd0AUET3iWI8BqyxXlGOV/3lN0Zq', '0', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-08-27 18:24:35', '2025-08-28 07:31:00', 0, 0, 0),
(8, 'Budi', 'budi', 'budi@gmail.com', '09893424835', '$2y$10$FGc4fcDrKG81ub0AM33hD.NDevoqxhoHubGrllfnO5TJYaE0j.Rdm', '0', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-08-28 07:36:01', '2025-08-28 07:36:01', 0, 0, 0),
(9, 'ayu', 'ayu', 'ayu@gmail.com', '081378237138', '$2y$10$8eJeX6VisRYEV7IWpr.80Olz0n.qWIS.BhtlEDdg8VWWpU4BpB28O', '1', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-08-28 07:39:08', '2025-08-28 07:39:08', 0, 0, 0),
(10, 'ida', 'ida', 'ida@gmail.com', '0813628283', '$2y$10$aM1iS5gFom60tvN1tzqBKeNMzOGTw05XLtClHxwRk0yAG.5NqZGz.', '0', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1756293044/dummy-profile-pic-300x300_udkg39.png', '2025-08-28 07:40:21', '2025-08-28 07:40:21', 0, 0, 0);

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
  MODIFY `id_addon` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `alamat_pengantaran`
--
ALTER TABLE `alamat_pengantaran`
  MODIFY `id_alamat` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `etalase`
--
ALTER TABLE `etalase`
  MODIFY `id_etalase` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `favorite`
--
ALTER TABLE `favorite`
  MODIFY `id_favorite` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `gerai`
--
ALTER TABLE `gerai`
  MODIFY `id_gerai` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `gerai_profil`
--
ALTER TABLE `gerai_profil`
  MODIFY `id_gerai_profil` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `keranjang`
--
ALTER TABLE `keranjang`
  MODIFY `id_keranjang` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT for table `keranjang_item`
--
ALTER TABLE `keranjang_item`
  MODIFY `id_keranjang_item` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=104;

--
-- AUTO_INCREMENT for table `keranjang_item_addon`
--
ALTER TABLE `keranjang_item_addon`
  MODIFY `id_keranjang_item_addon` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=151;

--
-- AUTO_INCREMENT for table `menu`
--
ALTER TABLE `menu`
  MODIFY `id_menu` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `menu_addon`
--
ALTER TABLE `menu_addon`
  MODIFY `id_menu_addon` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `penjual_info`
--
ALTER TABLE `penjual_info`
  MODIFY `id_penjual_info` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `transaksi`
--
ALTER TABLE `transaksi`
  MODIFY `id_transaksi` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT for table `transaksi_item`
--
ALTER TABLE `transaksi_item`
  MODIFY `id_transaksi_item` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=53;

--
-- AUTO_INCREMENT for table `transaksi_item_addon`
--
ALTER TABLE `transaksi_item_addon`
  MODIFY `id_transaksi_item_addon` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=49;

--
-- AUTO_INCREMENT for table `ulasan`
--
ALTER TABLE `ulasan`
  MODIFY `id_ulasan` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id_users` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

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
