import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The type scale: Manrope for headlines, titles and numbers (geometric,
/// confident in bold), Inter for everything you read (clear at small
/// sizes). Both are bundled in assets/google_fonts. Numbers use tabular
/// figures so counters never jitter.
abstract final class GType {
  static const _tab = [FontFeature.tabularFigures()];

  static TextStyle _head({required double size, required FontWeight w, double spacing = 0, double height = 1.2, List<FontFeature>? features}) =>
      GoogleFonts.manrope(fontSize: size, fontWeight: w, letterSpacing: spacing, height: height, fontFeatures: features);

  static TextStyle _text({required double size, required FontWeight w, double spacing = 0, double height = 1.4, List<FontFeature>? features}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: w, letterSpacing: spacing, height: height, fontFeatures: features);

  static final TextStyle display = _head(size: 30, w: FontWeight.w800, spacing: -0.9, height: 1.12);
  static final TextStyle h1 = _head(size: 24, w: FontWeight.w800, spacing: -0.5, height: 1.2);
  static final TextStyle h2 = _head(size: 19.5, w: FontWeight.w700, spacing: -0.3, height: 1.24);
  static final TextStyle h3 = _head(size: 16.5, w: FontWeight.w700, spacing: -0.15, height: 1.3);
  static final TextStyle title = _text(size: 15, w: FontWeight.w600, spacing: -0.1, height: 1.32);
  static final TextStyle body = _text(size: 14.5, w: FontWeight.w400, height: 1.5);
  static final TextStyle bodyS = _text(size: 13.5, w: FontWeight.w400, height: 1.45);
  static final TextStyle label = _text(size: 13.5, w: FontWeight.w500, height: 1.28);
  static final TextStyle caption = _text(size: 12, w: FontWeight.w500, height: 1.32);
  static final TextStyle micro = _text(size: 10.5, w: FontWeight.w600, spacing: 0.4, height: 1.2);
  static final TextStyle numeral = _head(size: 28, w: FontWeight.w800, spacing: -0.8, height: 1.0, features: _tab);
  static final TextStyle figure = _head(size: 14.5, w: FontWeight.w700, height: 1.2, features: _tab);
}

extension GTextStyleX on TextStyle {
  TextStyle c(Color color) => copyWith(color: color);
  TextStyle w(FontWeight weight) => copyWith(fontWeight: weight);
}
