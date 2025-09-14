import 'package:flutter/material.dart';
import 'package:dpr_bites/features/user/models/review_page_model.dart';
import 'package:dpr_bites/features/user/services/review_page_service.dart';

class ReviewPage extends StatefulWidget {
  final int idTransaksi;
  final int idGerai;
  final String? idUser; // buyer id (legacy), no longer required
  final String geraiName;
  final String? listingPath; // URL or local path for store image
  final bool readOnly; // display only
  final int? initialRating;
  final String? initialKomentar;
  const ReviewPage({
    super.key,
    required this.idTransaksi,
    required this.idGerai,
    this.idUser,
    required this.geraiName,
    this.listingPath,
    this.readOnly = false,
    this.initialRating,
    this.initialKomentar,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late int _rating; // 1..5
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _anonymous = false; // user choose anonymity

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    if (widget.initialKomentar != null) {
      _controller.text = widget.initialKomentar!;
    }
    // If opened in read-only mode we cannot change anonymity.
  }

  Future<void> _submit() async {
    if (widget.readOnly) return;
    if (_rating == 0 || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final model = ReviewModel(
        idTransaksi: widget.idTransaksi,
        rating: _rating,
        komentar: _controller.text.trim(),
        anonymous: _anonymous,
      );
      final result = await ReviewService.submitReview(model);
      if (!result.success) {
        throw Exception(result.message ?? 'Gagal');
      }
      if (!mounted) return;
      await _showResultDialog(success: true);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        await _showResultDialog(success: false, message: _error);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showResultDialog({
    required bool success,
    String? message,
  }) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'result',
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return Opacity(
          opacity: curved.value,
          child: Transform.scale(
            scale: 0.9 + 0.1 * curved.value,
            child: _ResultDialog(success: success, message: message),
          ),
        );
      },
    );
    await Future.delayed(const Duration(milliseconds: 1250));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // close dialog
    }
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final idx = i + 1;
        final filled = _rating >= idx;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: widget.readOnly ? null : () => setState(() => _rating = idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  if (filled)
                    BoxShadow(
                      color: Colors.black.withOpacity(.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
                gradient: filled
                    ? const LinearGradient(
                        colors: [Color(0xFFB03056), Color(0xFFD9737F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: Border.all(
                  color: filled ? Colors.transparent : const Color(0xFFE0E0E0),
                  width: 1.2,
                ),
                color: filled ? null : Colors.white,
              ),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                size: 28,
                color: filled ? Colors.white : const Color(0xFFB0B0B0),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Beri Ulasan'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF602829),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Tutup',
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF4E6ED),
                      image:
                          widget.listingPath != null &&
                              widget.listingPath!.trim().isNotEmpty
                          ? DecorationImage(
                              image: widget.listingPath!.startsWith('http')
                                  ? NetworkImage(widget.listingPath!)
                                  : AssetImage(widget.listingPath!)
                                        as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child:
                        (widget.listingPath == null ||
                            widget.listingPath!.trim().isEmpty)
                        ? const Center(
                            child: Icon(
                              Icons.storefront_rounded,
                              size: 50,
                              color: Color(0xFFB03056),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.geraiName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF602829),
                      letterSpacing: .3,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildStars(),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.readOnly ? 'Komentar' : 'Komentar (opsional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E2E2)),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 5,
                      minLines: 3,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(fontSize: 14.5, height: 1.4),
                      decoration: InputDecoration(
                        hintText: widget.readOnly
                            ? 'Tidak ada komentar'
                            : 'Tulis pengalamanmu... (opsional)',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      readOnly: widget.readOnly,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (!widget.readOnly) ...[
                    // anonymity toggle slider style (minimal switch-like)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E2E2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Kirim sebagai anonim',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Hanya huruf pertama & terakhir nama yang terlihat',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _AnonSlider(
                            value: _anonymous,
                            onChanged: (v) => setState(() => _anonymous = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                  ],
                  if (!widget.readOnly)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_rating == 0 || _submitting)
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB03056),
                          disabledBackgroundColor: const Color(
                            0xFFB03056,
                          ).withOpacity(.35),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Kirim Ulasan'),
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // removed positioned close (moved to AppBar)
          ],
        ),
      ),
    );
  }
}

// Minimal custom slider switch for anonymity
class _AnonSlider extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AnonSlider({required this.value, required this.onChanged});
  @override
  State<_AnonSlider> createState() => _AnonSliderState();
}

class _AnonSliderState extends State<_AnonSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    if (widget.value) _c.value = 1;
  }

  @override
  void didUpdateWidget(covariant _AnonSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _c.forward();
      } else {
        _c.reverse();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: SizedBox(
        width: 64,
        height: 34,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final t = _anim.value;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(
                      const Color(0xFFE0E0E0),
                      const Color(0xFFB03056),
                      t,
                    )!,
                    Color.lerp(
                      const Color(0xFFD5D5D5),
                      const Color(0xFFD9737F),
                      t,
                    )!,
                  ],
                ),
                boxShadow: t > 0.1
                    ? [
                        BoxShadow(
                          color: const Color(0xFFB03056).withOpacity(.35 * t),
                          blurRadius: 10 * t,
                          offset: Offset(0, 3 * t),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.lerp(
                      Alignment.centerLeft,
                      Alignment.centerRight,
                      t,
                    )!,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.18 * t),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        t > 0.5
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 18,
                        color: t > 0.5
                            ? const Color(0xFFB03056)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Reusable modern minimal bottom sheet style route (slide up on enter, slide down on exit)
class ReviewSheetRoute extends PageRouteBuilder {
  final Widget child;
  ReviewSheetRoute(this.child)
    : super(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) => child,
      );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

// INTERNAL: animated dialog content
class _ResultDialog extends StatefulWidget {
  final bool success;
  final String? message;
  const _ResultDialog({required this.success, this.message});
  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _circle;
  late final Animation<double> _check; // 0..1 stroke percent

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _circle = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
    );
    _check = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.4, 1, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.success
        ? const Color(0xFF4CAF50)
        : const Color(0xFFD32F2F);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 220,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  return CustomPaint(
                    size: const Size(80, 80),
                    painter: _ResultPainter(
                      progressCircle: _circle.value,
                      progressCheck: _check.value,
                      success: widget.success,
                      color: color,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                widget.success ? 'Terima Kasih!' : 'Gagal',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF602829),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.success
                    ? 'Ulasan kamu tersimpan.'
                    : (widget.message ?? 'Terjadi kesalahan'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.3,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPainter extends CustomPainter {
  final double progressCircle; // 0..1 scale draw circle
  final double progressCheck; // 0..1 draw path
  final bool success;
  final Color color;
  _ResultPainter({
    required this.progressCircle,
    required this.progressCheck,
    required this.success,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * (0.2 + 0.8 * progressCircle);
    final bgPaint = Paint()
      ..color = color.withOpacity(.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);
    final ringPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * 3.1416 / 180,
      2 * 3.1416 * progressCircle,
      false,
      ringPaint,
    );
    if (progressCheck > 0) {
      final path = Path();
      if (success) {
        // check path
        final start = Offset(
          center.dx - radius * 0.55,
          center.dy - radius * 0.05,
        );
        final mid = Offset(center.dx - radius * 0.1, center.dy + radius * 0.45);
        final end = Offset(center.dx + radius * 0.6, center.dy - radius * 0.4);
        final points = [start, mid, end];
        final totalSegments = points.length - 1;
        double covered = progressCheck * totalSegments;
        for (int i = 0; i < totalSegments; i++) {
          final p1 = points[i];
          final p2 = points[i + 1];
          double segProgress = (covered - i).clamp(0.0, 1.0);
          if (segProgress <= 0) continue;
          final drawTo = Offset(
            p1.dx + (p2.dx - p1.dx) * segProgress,
            p1.dy + (p2.dy - p1.dy) * segProgress,
          );
          path.moveTo(p1.dx, p1.dy);
          path.lineTo(drawTo.dx, drawTo.dy);
        }
      } else {
        // cross path
        final diag1Start = Offset(
          center.dx - radius * 0.5,
          center.dy - radius * 0.5,
        );
        final diag1End = Offset(
          center.dx + radius * 0.5,
          center.dy + radius * 0.5,
        );
        final diag2Start = Offset(
          center.dx + radius * 0.5,
          center.dy - radius * 0.5,
        );
        final diag2End = Offset(
          center.dx - radius * 0.5,
          center.dy + radius * 0.5,
        );
        final paths = [
          [diag1Start, diag1End],
          [diag2Start, diag2End],
        ];
        double total = progressCheck * paths.length;
        for (int i = 0; i < paths.length; i++) {
          double segP = (total - i).clamp(0.0, 1.0);
          if (segP <= 0) continue;
          final s = paths[i][0];
          final e = paths[i][1];
          final drawTo = Offset(
            s.dx + (e.dx - s.dx) * segP,
            s.dy + (e.dy - s.dy) * segP,
          );
          path.moveTo(s.dx, s.dy);
          path.lineTo(drawTo.dx, drawTo.dy);
        }
      }
      final checkPaint = Paint()
        ..color = color
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ResultPainter old) =>
      old.progressCircle != progressCircle ||
      old.progressCheck != progressCheck ||
      old.color != color ||
      old.success != success;
}
