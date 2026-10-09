import 'package:flutter/material.dart';
import '../engine/word_engine.dart';
import 'press_themes.dart';

/// The Letterpress Printshop design system for Word Guess.
/// Wooden type blocks, ink, brass, heavy paper. No neon, no cyberpunk,
/// no generic Material look.
///
/// All widgets accept an optional [PressThemeDef]; they default to the
/// classic Printshop Oak theme.
class Press {
  static const displayFont = 'serif';

  static TextStyle display(double size,
          {Color? color, PressThemeDef? theme}) =>
      TextStyle(
        fontFamily: displayFont,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: Color(0xFF1A0F08), offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, PressThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme?.paper ?? const Color(0xFFF1E6CE),
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, PressThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 0.8,
      );

  static ThemeData theme([PressThemeDef? t]) {
    t ??= PressThemes.byId('classic');
    final light = t.id == 'ivory' || t.id == 'porcelain';
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.bg,
      colorScheme: ColorScheme(
        brightness: light ? Brightness.light : Brightness.dark,
        primary: t.accent,
        onPrimary: t.bgDeep,
        secondary: t.accentLight,
        onSecondary: t.bgDeep,
        surface: t.paper,
        onSurface: t.ink,
        error: t.playerColors[0],
        onError: t.paper,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
        bodyMedium: body(14, theme: t),
        labelLarge: label(14, theme: t),
      ),
      dialogTheme: DialogThemeData(backgroundColor: t.paper),
    );
  }
}

Color _mix(Color a, Color b, double f) => Color.fromARGB(
      255,
      (a.r * f + b.r * (1 - f)).round(),
      (a.g * f + b.g * (1 - f)).round(),
      (a.b * f + b.b * (1 - f)).round(),
    );

Color _markColor(Mark m, PressThemeDef t) {
  switch (m) {
    case Mark.correct:
      return t.correct;
    case Mark.present:
      return t.present;
    case Mark.absent:
      return t.absent;
    case Mark.none:
      return t.paperDeep;
  }
}

/// Letter-tile decoration in the current tile style + theme.
/// Revealed tiles press the feedback color into the tile's material.
BoxDecoration tileDecoration(
    PressThemeDef t, int style, Mark mark, double radius) {
  if (mark == Mark.none) {
    final base = TileStyles.base(style, t);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: base,
      ),
      border: Border.all(color: TileStyles.edge(style), width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          offset: const Offset(0, 3),
          blurRadius: 5,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.18),
          offset: const Offset(0, -1),
          blurRadius: 1,
        ),
      ],
    );
  }
  final c = _markColor(mark, t);
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_mix(c, Colors.white, 0.18), _mix(c, Colors.black, 0.28)],
    ),
    border: Border.all(color: _mix(c, Colors.black, 0.45), width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.5),
        offset: const Offset(0, 3),
        blurRadius: 6,
      ),
    ],
  );
}

/// Letter ink on a tile face.
Color tileInk(PressThemeDef t, int style, Mark mark) {
  if (mark == Mark.none) return TileStyles.ink(style);
  if (mark == Mark.absent) return t.paper.withValues(alpha: 0.75);
  return Colors.white;
}

// ---------------------------------------------------------------------------
/// Paper-textured background with a warm vignette, theme-aware.
class PaperBackdrop extends StatelessWidget {
  final Widget child;
  final PressThemeDef? theme;
  const PaperBackdrop({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? PressThemes.byId('classic');
    return Container(
      decoration: BoxDecoration(color: t.bg),
      child: CustomPaint(
        painter: _PaperPainter(t),
        child: child,
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  final PressThemeDef t;
  _PaperPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final vignette = RadialGradient(
      center: const Alignment(0, -0.25),
      radius: 1.2,
      colors: [
        t.bgDeep.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: 0.45),
      ],
    );
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = vignette.createShader(
            Rect.fromLTWH(0, 0, size.width, size.height)));
    // Faint paper fibers.
    final fiber = Paint()
      ..color = t.accent.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (double y = 12; y < size.height; y += 46) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 8), fiber);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPainter old) => old.t.id != t.id;
}

// ---------------------------------------------------------------------------
/// Raised brass button with a satisfying physical press.
class PressButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final PressThemeDef? theme;
  final double width;
  final double fontSize;
  const PressButton({
    super.key,
    required this.label,
    required this.onTap,
    this.theme,
    this.width = 260,
    this.fontSize = 18,
  });

  @override
  State<PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<PressButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ?? PressThemes.byId('classic');
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 14),
        transform: Matrix4.identity()..scale(_down ? 0.96 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _down
                ? [t.accentDark, t.accent]
                : [t.accentLight, t.accent, t.accentDark],
          ),
          border: Border.all(color: t.accentLight, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              offset: Offset(0, _down ? 1 : 5),
              blurRadius: _down ? 2 : 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: Press.label(widget.fontSize,
              theme: t, color: t.bgDeep),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class PressToggle extends StatelessWidget {
  final PressThemeDef theme;
  final bool value;
  final ValueChanged<bool> onChanged;
  const PressToggle(
      {super.key,
      required this.theme,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 58,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value
              ? theme.accent.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.35),
          border: Border.all(
              color: theme.accent.withValues(alpha: 0.6), width: 1.5),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.paper, theme.paperDeep],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class SettingRow extends StatelessWidget {
  final PressThemeDef theme;
  final String label;
  final Widget control;
  const SettingRow(
      {super.key,
      required this.theme,
      required this.label,
      required this.control});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Press.body(16, theme: theme)),
          ),
          control,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Wood-framed card panel.
class PressCard extends StatelessWidget {
  final PressThemeDef theme;
  final String title;
  final Widget child;
  const PressCard(
      {super.key,
      required this.theme,
      required this.title,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.bgDeep.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(color: theme.accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: Press.display(20, theme: theme)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class PressChip extends StatelessWidget {
  final PressThemeDef theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const PressChip(
      {super.key,
      required this.theme,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? theme.accent.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: selected
                ? theme.accentLight
                : theme.accent.withValues(alpha: 0.5),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: Press.label(13,
              theme: theme,
              color: selected ? theme.bgDeep : theme.paper),
        ),
      ),
    );
  }
}
