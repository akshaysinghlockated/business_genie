import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/type.dart';

/// A text field: label above, grey fill, and a darker grey edge on focus (the
/// design review: focus is grey, never indigo). Errors sit under the field in
/// plain words.
class GInput extends StatefulWidget {
  const GInput({
    super.key,
    this.label,
    required this.hint,
    required this.controller,
    this.error,
    this.keyboardType,
    this.icon,
    this.autofocus = false,
    this.onSubmitted,
    this.onChanged,
    this.textInputAction,
    this.maxLines = 1,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final String? label;
  final String hint;
  final TextEditingController controller;
  final String? error;
  final TextInputType? keyboardType;
  final IconData? icon;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final int maxLines;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  State<GInput> createState() => _GInputState();
}

class _GInputState extends State<GInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final hasError = widget.error != null;
    final edge = hasError ? g.danger : (_focus.hasFocus ? g.ink3 : Colors.transparent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[Text(widget.label!, style: GType.label.c(g.ink2)), const SizedBox(height: 8)],
        AnimatedContainer(
          duration: GMotion.of(context, GMotion.quick),
          curve: GMotion.effects,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: widget.maxLines > 1 ? 12 : 0),
          constraints: const BoxConstraints(minHeight: 52),
          decoration: ShapeDecoration(
            color: g.card,
            shape: GShape.of(16, side: BorderSide(color: edge, width: 1.2)),
            shadows: _focus.hasFocus && !hasError ? [BoxShadow(color: g.ink3.withValues(alpha: .15), spreadRadius: 3)] : const [],
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: g.ink3), const SizedBox(width: 10)],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                  maxLines: widget.maxLines,
                  minLines: 1,
                  autofillHints: widget.autofillHints,
                  textCapitalization: widget.textCapitalization,
                  style: GType.body.c(g.ink),
                  cursorColor: g.ink,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: GType.body.c(g.ink3),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: GMotion.of(context, GMotion.quick),
          curve: GMotion.easeOut,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(widget.error!, style: GType.caption.c(g.danger)),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Six boxes for the sign-in code, backed by one hidden field so paste and
/// SMS autofill work.
class GCodeInput extends StatefulWidget {
  const GCodeInput({super.key, required this.controller, required this.onCompleted, this.error = false});

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final bool error;

  @override
  State<GCodeInput> createState() => _GCodeInputState();
}

class _GCodeInputState extends State<GCodeInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final text = widget.controller.text;
    return GestureDetector(
      onTap: _focus.requestFocus,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: GMotion.of(context, GMotion.quick),
                    height: 56,
                    alignment: Alignment.center,
                    decoration: GShape.fill(
                      g.card,
                      14,
                      side: BorderSide(
                        color: widget.error ? g.danger : (_focus.hasFocus && i == text.length.clamp(0, 5) ? g.ink3 : Colors.transparent),
                        width: 1.2,
                      ),
                    ),
                    child: Text(i < text.length ? text[i] : '', style: GType.h2.c(g.ink).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                  ),
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                showCursor: false,
                enableInteractiveSelection: false,
                onChanged: (v) {
                  setState(() {});
                  if (v.length == 6) widget.onCompleted(v);
                },
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
