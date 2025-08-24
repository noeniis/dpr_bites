import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

// 1. Custom Empty Card
class CustomEmptyCard extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final Widget? child;

  const CustomEmptyCard({
    Key? key,
    this.width,
    this.height,
    this.margin,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF767070), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// 2. TextField Line (Profile Display)
class TextFieldLine extends StatefulWidget {
  final String label;
  final String value;
  final bool obscure;
  final bool editable;
  final TextEditingController? controller;
  final Color underlineColor;

  const TextFieldLine({
    super.key,
    required this.label,
    required this.value,
    this.obscure = false,
    this.editable = false,
    this.controller,
    this.underlineColor = Colors.black, // default hitam
  });

  @override
  State<TextFieldLine> createState() => _TextFieldLineState();
}

class _TextFieldLineState extends State<TextFieldLine> {
  late TextEditingController _controller;
  // bool _hasCleared = false; // Tidak perlu clear otomatis

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 14)),
        widget.editable
            ? SizedBox(
                height: 32,
                child: TextField(
                  controller: _controller,
                  obscureText: widget.obscure,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textInputAction: TextInputAction.done,
                  minLines: 1,
                  maxLines: 1,
                  expands: false,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: "",
                  ),
                ),
              )
            : Text(
                widget.obscure ? "*******" : widget.value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
        Container(
          height: 2,
          margin: const EdgeInsets.only(top: 2, bottom: 12),
          color: widget.underlineColor,
        ),
      ],
    );
  }
}

// 3. Custom Input Field
class CustomInputField extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final String? obscuringCharacter;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const CustomInputField({
    Key? key,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.obscuringCharacter,
    this.prefixIcon,
    this.suffixIcon,
    this.onSubmitted,
    this.inputFormatters,
  }) : super(key: key);

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      obscureText: widget.obscureText,
      obscuringCharacter: widget.obscuringCharacter ?? '•',
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD53D3D), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD53D3D), width: 2.0),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD53D3D), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      onSubmitted: widget.onSubmitted,
    );
  }
}

// 4. Custom Filter Chip
class CustomFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? icon;

  const CustomFilterChip({
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD53D3D).withOpacity(0.12)
              : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFFD53D3D) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) icon!,
            if (icon != null) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFFD53D3D) : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. Custom Button Oval (Gradient)
class CustomButtonOval extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const CustomButtonOval({required this.text, this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onPressed,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD53D3D), Color(0xFF602829)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// 6. Custom Button Kotak (Gradient)
class CustomButtonKotak extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final double? width;

  const CustomButtonKotak({
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.width,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;
    final Color bgColor = backgroundColor ?? Colors.transparent;
    final Color fgColor =
        textColor ??
        (isDisabled ? Colors.white.withOpacity(0.55) : Colors.white);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPressed,
      child: Container(
        height: 48,
        width: width,
        decoration: BoxDecoration(
          color: backgroundColor != null ? bgColor : null,
          gradient: (backgroundColor == null)
              ? LinearGradient(
                  colors: isDisabled
                      ? [
                          const Color(0xFFD53D3D).withOpacity(0.35),
                          const Color(0xFF602829).withOpacity(0.35),
                        ]
                      : [const Color(0xFFD53D3D), const Color(0xFF602829)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: (isDisabled
                  ? Colors.redAccent.withOpacity(0.04)
                  : Colors.redAccent.withOpacity(0.07)),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: fgColor,
            fontSize: fontSize ?? 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

//7. Custom Button Filter Kotak
class CustomFilterChipKotak extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? icon;

  const CustomFilterChipKotak({
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD53D3D).withOpacity(0.12)
              : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFFD53D3D) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) icon!,
            if (icon != null) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFFD53D3D) : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
