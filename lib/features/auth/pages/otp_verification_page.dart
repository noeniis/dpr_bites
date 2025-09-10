import 'package:flutter/material.dart';
import '../../../common/widgets/custom_widgets.dart';
import '../../../app/gradient_background.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../models/otp_verification_page_model.dart';
import '../services/otp_verification_page_service.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  const OtpVerificationPage({Key? key, required this.email}) : super(key: key);

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _isLoading = false;
        _error = 'OTP harus 6 digit';
      });
      return;
    }
    try {
      final result = await OtpVerificationPageService.verify(
        OtpVerifyRequest(email: widget.email, otp: otp),
      );
      if (result.success) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          '/reset-password',
          arguments: {'email': widget.email, 'otp': otp},
        );
      } else {
        setState(() {
          _error = result.message ?? 'OTP salah';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.11),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Masukkan kode OTP yang dikirim ke email Anda",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  autoFocus: true,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(8),
                    fieldHeight: 48,
                    fieldWidth: 40,
                    activeColor: const Color(0xFFD53D3D),
                    selectedColor: const Color(0xFFD53D3D),
                    inactiveColor: Colors.grey.shade300,
                  ),
                  animationDuration: const Duration(milliseconds: 200),
                  onChanged: (value) {},
                  onCompleted: (value) {
                    _otpController.text = value;
                  },
                  enableActiveFill: false,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 22),
                CustomButtonKotak(
                  text: _isLoading ? 'Memeriksa...' : 'Verifikasi',
                  onPressed: _isLoading ? null : _verifyOtp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
