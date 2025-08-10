import 'custom_widgets.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:flutter/material.dart';

class PlaygroundPage extends StatelessWidget {
  const PlaygroundPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy controller untuk input/input field
    final TextEditingController demoController = TextEditingController(text: 'Contoh isi input');
    final TextEditingController editProfileController = TextEditingController(text: 'Bisa di-edit!');

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Widget Playground',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // CustomButtonOval (Gradien Oval)
                CustomButtonOval(
                  text: 'Tombol Oval (Gradient)',
                  onPressed: () {},
                ),
                const SizedBox(height: 16),

                // CustomButtonKotak (Gradien Kotak)
                CustomButtonKotak(
                  text: 'Tombol Kotak (Gradient)',
                  onPressed: () {},
                ),
                const SizedBox(height: 16),

                // CustomEmptyCard
                CustomEmptyCard(
                  width: double.infinity,
                  height: 80,
                  child: Center(child: Text('CustomEmptyCard - Kotak Kosong')),
                ),
                const SizedBox(height: 16),

                // CustomInputField
                CustomInputField(
                  hintText: 'Masukkan sesuatu...',
                  controller: demoController,
                  prefixIcon: const Icon(Icons.email),
                ),
                const SizedBox(height: 16),

                // CustomFilterChip
                Wrap(
                  spacing: 8,
                  children: [
                    CustomFilterChip(
                      label: "Semua",
                      selected: true,
                      onTap: () {},
                    ),
                    CustomFilterChip(
                      label: "Ketersediaan",
                      selected: false,
                      onTap: () {},
                    ),
                    CustomFilterChip(
                      label: "Layanan",
                      selected: false,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // CustomFilterChipKotak
                Wrap(
                  spacing: 8,
                  children: [
                    CustomFilterChipKotak(
                      label: "Semua",
                      selected: true,
                      onTap: () {},
                    ),
                    CustomFilterChipKotak(
                      label: "Ketersediaan",
                      selected: false,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // TextFieldLine (Display Mode)
                const Text(
                  "TextFieldLine (Display/Readonly):",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFieldLine(
                  label: "Nama",
                  value: "Noeni Indah Sulistiyani",
                ),
                TextFieldLine(
                  label: "Username",
                  value: "noeniindahs27",
                ),
                TextFieldLine(
                  label: "No HP",
                  value: "085719832740",
                ),
                TextFieldLine(
                  label: "Password",
                  value: "password",
                  obscure: true,
                ),
                const SizedBox(height: 16),

                // TextFieldLine (Editable/Input Mode)
                const Text(
                  "TextFieldLine (Editable):",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFieldLine(
                  label: "Edit Profil",
                  value: "",
                  editable: true,
                  controller: editProfileController,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}