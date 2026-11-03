import 'package:flutter/material.dart';

/// Business Genie's colours, taken from the mobile prototype. Ink on warm
/// white, blue only for "on", violet only for Genie (AI), and green / amber /
/// red only for status.
/// Read through `context.g`, never hard-coded in a widget.
@immutable
class GPalette extends ThemeExtension<GPalette> {
  const GPalette({
    required this.ground,
    required this.surface,
    required this.card,
    required this.stone,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.rule,
    required this.ruleStrong,
    required this.onInk,
    required this.accent,
    required this.accentSoft,
    required this.ai,
    required this.aiSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.glass,
    required this.glassEdge,
    required this.shadow,
    required this.scrim,
  });

  /// The page behind the header.
  final Color ground;

  /// The sheet content sits on.
  final Color surface;

  /// Flat grey cards, tracks and fields on [surface].
  final Color card;

  /// Selected chips and thumbs (the design review asks for stone, not black).
  final Color stone;

  final Color ink, ink2, ink3, ink4;
  final Color rule, ruleStrong;

  /// Text on an ink fill.
  final Color onInk;

  /// Toggles on, links, focus of the week strip.
  final Color accent, accentSoft;

  /// Genie only.
  final Color ai, aiSoft;

  final Color success, successSoft, warning, warningSoft, danger, dangerSoft;
  final Color glass, glassEdge, shadow, scrim;

  // Values from the Business Genie mobile prototype (Business Genie.html):
  // --bg, --surface, --ink and its 62 / 40 / 20 % steps, --line, --line-2,
  // --fill, --fill-2, --blue, --dot (Genie), --green, --amber, --red.
  static const light = GPalette(
    ground: Color(0xFFFAFAF9),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFF2F2F1),
    stone: Color(0xFFECEBE8),
    ink: Color(0xFF18181A),
    ink2: Color(0x9E18181A),
    ink3: Color(0x6618181A),
    ink4: Color(0x3318181A),
    rule: Color(0x1418181A),
    ruleStrong: Color(0x2418181A),
    onInk: Color(0xFFFFFFFF),
    accent: Color(0xFF3579D7),
    accentSoft: Color(0xFFE9F0FA),
    ai: Color(0xFF7C5CFF),
    aiSoft: Color(0xFFF1EEFF),
    success: Color(0xFF1F9D55),
    successSoft: Color(0xFFE6F4EC),
    warning: Color(0xFFC98500),
    warningSoft: Color(0xFFFAF1DE),
    danger: Color(0xFFD93F44),
    dangerSoft: Color(0xFFFBE9E9),
    glass: Color(0xD1FFFFFF),
    glassEdge: Color(0xF2FFFFFF),
    shadow: Color(0x241E1C18),
    scrim: Color(0x6618181A),
  );

  static const dark = GPalette(
    ground: Color(0xFF0C0C0D),
    surface: Color(0xFF151517),
    card: Color(0xFF1E1E20),
    stone: Color(0xFF2A2A2D),
    ink: Color(0xFFF2F2F0),
    ink2: Color(0x9EF2F2F0),
    ink3: Color(0x66F2F2F0),
    ink4: Color(0x33F2F2F0),
    rule: Color(0x14FFFFFF),
    ruleStrong: Color(0x24FFFFFF),
    onInk: Color(0xFF18181A),
    accent: Color(0xFF3579D7),
    accentSoft: Color(0xFF17243A),
    ai: Color(0xFF9B85FF),
    aiSoft: Color(0xFF221D3D),
    success: Color(0xFF3DBE73),
    successSoft: Color(0xFF14291D),
    warning: Color(0xFFE2A33A),
    warningSoft: Color(0xFF2E2310),
    danger: Color(0xFFF0676B),
    dangerSoft: Color(0xFF341A1B),
    glass: Color(0xD6242428),
    glassEdge: Color(0x24FFFFFF),
    shadow: Color(0x8C000000),
    scrim: Color(0x99000000),
  );

  @override
  GPalette copyWith() => this;

  @override
  GPalette lerp(GPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return GPalette(
      ground: l(ground, other.ground),
      surface: l(surface, other.surface),
      card: l(card, other.card),
      stone: l(stone, other.stone),
      ink: l(ink, other.ink),
      ink2: l(ink2, other.ink2),
      ink3: l(ink3, other.ink3),
      ink4: l(ink4, other.ink4),
      rule: l(rule, other.rule),
      ruleStrong: l(ruleStrong, other.ruleStrong),
      onInk: l(onInk, other.onInk),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      ai: l(ai, other.ai),
      aiSoft: l(aiSoft, other.aiSoft),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      glass: l(glass, other.glass),
      glassEdge: l(glassEdge, other.glassEdge),
      shadow: l(shadow, other.shadow),
      scrim: l(scrim, other.scrim),
    );
  }
}

extension GPaletteContext on BuildContext {
  GPalette get g => Theme.of(this).extension<GPalette>() ?? GPalette.light;
}
