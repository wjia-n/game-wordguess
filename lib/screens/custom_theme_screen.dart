import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/letterpress.dart';
import '../theme/press_themes.dart';

/// Custom theme creator (PRO): design your own printshop ink & paper.
class CustomThemeScreen extends StatefulWidget {
  final WordAudio audio;
  final WordSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  WordSettings get _s => widget.settings;
  PressThemeDef get _t => _s.customTheme;

  // A printshop ink rack: real-world ink, paper and metal tones.
  static const _swatches = [
    0xFF2E1F14, 0xFF3B2416, 0xFF1A1109, 0xFF000000, 0xFF4A1F14,
    0xFFC9A227, 0xFFE8CE7A, 0xFFB87333, 0xFF8A6D1A, 0xFFD4AF37,
    0xFFF1E6CE, 0xFFFBF6E9, 0xFFFFFFFF, 0xFFDCCDA9, 0xFF9A8C72,
    0xFFA31621, 0xFF1D4E9E, 0xFF1B7A4D, 0xFF2E7D32, 0xFFE8A100,
    0xFF8D8D8D, 0xFF123326, 0xFF1C2438, 0xFF0F3A3A, 0xFF2E3440,
    0xFF7E8698, 0xFFE09E5A, 0xFF5E8AC0, 0xFF8E44AD, 0xFFE74C3C,
  ];

  static const _labels = {
    'bg': 'Background',
    'bgDeep': 'Deep shadow',
    'paper': 'Paper',
    'paperDeep': 'Paper shade',
    'accent': 'Brass accent',
    'accentLight': 'Accent light',
    'accentDark': 'Accent dark',
    'ink': 'Ink (text)',
    'muted': 'Muted text',
    'correct': 'Correct green',
    'present': 'Present amber',
    'absent': 'Absent grey',
    'pc0': 'Player one color',
    'pc1': 'Player two color',
  };

  @override
  Widget build(BuildContext context) {
    final t = PressThemes.byId(_s.themeId, custom: _s.customTheme);
    return PaperBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title:
              Text('My Creation', style: Press.display(22, theme: t)),
          centerTitle: true,
        ),
        body: ListenableBuilder(
          listenable: _s,
          builder: (_, _) => SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mix your own inks and papers. Tap a swatch to re-ink a part.',
                  style: Press.body(14, theme: t),
                ),
                const SizedBox(height: 12),
                // Live preview strip.
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _t.bg,
                    border:
                        Border.all(color: t.accent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final m in [1, 2, 3])
                        Container(
                          width: 44,
                          height: 44,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: m == 1
                                  ? [_t.correct, _t.correct]
                                  : m == 2
                                      ? [_t.present, _t.present]
                                      : [_t.paper, _t.paperDeep],
                            ),
                            border:
                                Border.all(color: _t.accentDark, width: 2),
                          ),
                          child: Text(
                            ['W', 'O', 'R'][m - 1],
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: m == 3 ? _t.ink : Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final key in _labels.keys)
                  _ColorRow(
                    theme: t,
                    label: _labels[key]!,
                    current: _s.customColors[key]!,
                    onPick: (c) {
                      widget.audio.click();
                      _s.setCustomColor(key, c);
                    },
                  ),
                const SizedBox(height: 10),
                Center(
                  child: PressButton(
                    label: 'Use this theme',
                    width: 240,
                    theme: t,
                    onTap: () {
                      widget.audio.click();
                      _s.setTheme('custom');
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      widget.audio.click();
                      _s.resetCustomColors();
                    },
                    child: Text('Reset to Printshop Oak',
                        style: Press.label(13, theme: t)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final PressThemeDef theme;
  final String label;
  final int current;
  final ValueChanged<int> onPick;
  const _ColorRow({
    required this.theme,
    required this.label,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(current),
                  border: Border.all(
                      color: theme.accentLight, width: 1.5),
                ),
              ),
              const SizedBox(width: 10),
              Text(label, style: Press.body(15, theme: theme)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in _CustomThemeScreenState._swatches)
                GestureDetector(
                  onTap: () => onPick(c),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(c),
                      border: Border.all(
                        color: current == c
                            ? theme.accentLight
                            : Colors.black.withValues(alpha: 0.3),
                        width: current == c ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
