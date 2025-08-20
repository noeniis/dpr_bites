-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 20, 2025 at 08:45 AM
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
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  `qris_path` varchar(255) DEFAULT NULL,
  `status_pengajuan` enum('pending','approved','rejected') DEFAULT 'pending',
  `sertifikasi_halal` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  `tersedia` tinyint(1) DEFAULT 1,
  `pengantaran` tinyint(1) DEFAULT 0,
  `pickup` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `menu_addon`
--

CREATE TABLE `menu_addon` (
  `id_menu_addon` int(11) NOT NULL,
  `id_menu` int(11) NOT NULL,
  `id_addon` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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

-- --------------------------------------------------------

--
-- Table structure for table `transaksi`
--

CREATE TABLE `transaksi` (
  `id_transaksi` int(11) NOT NULL,
  `booking_id` varchar(50) NOT NULL,
  `id_users` int(11) NOT NULL,
  `id_gerai` int(11) NOT NULL,
  `STATUS` enum('konfirmasi_ketersediaan','konfirmasi_pembayaran','disiapkan','diantar','pickup','selesai','dibatalkan') DEFAULT 'konfirmasi_ketersediaan',
  `metode_pembayaran` enum('qris','cash') NOT NULL,
  `total_harga` int(11) NOT NULL,
  `biaya_pengantaran` int(11) DEFAULT 5000,
  `jenis_pengantaran` enum('pengantaran','pickup') NOT NULL,
  `catatan_pembatalan` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  `subtotal` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `transaksi_item_addon`
--

CREATE TABLE `transaksi_item_addon` (
  `id_transaksi_item_addon` int(11) NOT NULL,
  `id_transaksi_item` int(11) NOT NULL,
  `id_addon` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  `role` enum('pegawai','penjual','koperasi') NOT NULL,
  `photo_path` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id_users`, `nama_lengkap`, `username`, `email`, `no_hp`, `password_hash`, `role`, `photo_path`, `created_at`, `updated_at`) VALUES
(1, 'Noeni', 'noeniis', 'noeni@gmail.com', '0868373984', '$2y$10$Ypn7F39UBtO4peSt2GPc4.ZKhuDVde31qxgsf4VI.Zzu3mKBSoezO', 'pegawai', 'https://res.cloudinary.com/dip8i3f6x/image/upload/v1755671388/vzd6qahdgm9nz7zsdrkz.jpg', '2025-08-20 08:46:39', '2025-08-20 13:30:28'),
(2, 'raihan ade', 'raihan', 'raihan@gmail.com', '0896374378', '$2y$10$0nqBOzEiOOBfqmCCUEREceSOlRZrmk/J1A/Pr40KTvGY9E1ATOFiK', 'penjual', NULL, '2025-08-20 08:47:38', '2025-08-20 08:47:38'),
(3, 'Noeni Indh', 'noeniindh', 'noeniindahs27@gmail.com', '085719832740', '$2y$10$YHyvHA7gHjTa2ZtE643DUOYTbtOHQwoFkmOk8tAvYcn2UZywX5oAK', 'pegawai', NULL, '2025-08-20 08:56:09', '2025-08-20 08:56:09'),
(4, 'Raihan Ade Purnomo', 'raihanadep', 'raihanadeprnm@gmail.com', '081385321390', '$2y$10$Kul7xV7qwqX.ywMgLd6X0O5QlfQF/Pz1SYb6SJtiPtywa0fc/5h2K', 'pegawai', NULL, '2025-08-20 11:06:08', '2025-08-20 12:23:52');

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
  ADD KEY `id_gerai` (`id_gerai`);

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
  MODIFY `id_addon` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `alamat_pengantaran`
--
ALTER TABLE `alamat_pengantaran`
  MODIFY `id_alamat` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `etalase`
--
ALTER TABLE `etalase`
  MODIFY `id_etalase` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `favorite`
--
ALTER TABLE `favorite`
  MODIFY `id_favorite` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `gerai`
--
ALTER TABLE `gerai`
  MODIFY `id_gerai` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `gerai_profil`
--
ALTER TABLE `gerai_profil`
  MODIFY `id_gerai_profil` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `menu`
--
ALTER TABLE `menu`
  MODIFY `id_menu` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `menu_addon`
--
ALTER TABLE `menu_addon`
  MODIFY `id_menu_addon` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `penjual_info`
--
ALTER TABLE `penjual_info`
  MODIFY `id_penjual_info` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `transaksi`
--
ALTER TABLE `transaksi`
  MODIFY `id_transaksi` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `transaksi_item`
--
ALTER TABLE `transaksi_item`
  MODIFY `id_transaksi_item` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `transaksi_item_addon`
--
ALTER TABLE `transaksi_item_addon`
  MODIFY `id_transaksi_item_addon` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ulasan`
--
ALTER TABLE `ulasan`
  MODIFY `id_ulasan` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id_users` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

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
-- Constraints for table `menu`
--
ALTER TABLE `menu`
  ADD CONSTRAINT `menu_ibfk_1` FOREIGN KEY (`id_gerai`) REFERENCES `gerai` (`id_gerai`),
  ADD CONSTRAINT `menu_ibfk_2` FOREIGN KEY (`id_etalase`) REFERENCES `etalase` (`id_etalase`);

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
