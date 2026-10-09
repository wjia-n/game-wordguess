import 'package:flutter/material.dart';

/// Theme, tile-style catalogs for Word Guess — "The Letterpress Printshop".
///
/// Wooden type blocks, ink rollers, brass, and heavy paper. No neon, no
/// cyberpunk, no generic Material look. Feedback colors stay recognizable
/// (green = right spot, amber = right letter) with per-theme shades.
class PressThemeDef {
  final String id;
  final String name;
  final Color bg; // deep background
  final Color bgDeep; // vignette / panel depth
  final Color paper; // primary surface
  final Color paperDeep; // pressed paper shadow
  final Color accent; // brass / copper / ink accents
  final Color accentLight;
  final Color accentDark;
  final Color ink; // primary text
  final Color muted; // dimmed text
  final Color correct; // right letter, right spot
  final Color present; // right letter, wrong spot
  final Color absent; // not in word
  final List<Color> playerColors;
  final List<String> playerColorNames;

  const PressThemeDef({
    required this.id,
    required this.name,
    required this.bg,
    required this.bgDeep,
    required this.paper,
    required this.paperDeep,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.ink,
    required this.muted,
    required this.correct,
    required this.present,
    required this.absent,
    required this.playerColors,
    required this.playerColorNames,
  });
}

class PressThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'walnut',
    'ivory',
    'emerald',
  ];

  static const List<PressThemeDef> all = [
    PressThemeDef(
      id: 'classic',
      name: 'Printshop Oak',
      bg: Color(0xFF2E1F14),
      bgDeep: Color(0xFF1A1109),
      paper: Color(0xFFF1E6CE),
      paperDeep: Color(0xFFDCCDA9),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ink: Color(0xFF2E1F14),
      muted: Color(0xFF8A7961),
      correct: Color(0xFF2E7D32),
      present: Color(0xFFE8A100),
      absent: Color(0xFF8D8D8D),
      playerColors: [Color(0xFFA31621), Color(0xFF1D4E9E)],
      playerColorNames: ['Ruby', 'Sapphire'],
    ),
    PressThemeDef(
      id: 'walnut',
      name: 'Walnut Desk',
      bg: Color(0xFF3B2416),
      bgDeep: Color(0xFF241309),
      paper: Color(0xFFEFE3C8),
      paperDeep: Color(0xFFD8C49E),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ink: Color(0xFF3B2416),
      muted: Color(0xFF97805F),
      correct: Color(0xFF388E3C),
      present: Color(0xFFD89B00),
      absent: Color(0xFF9A9A9A),
      playerColors: [Color(0xFFA31621), Color(0xFF1D4E9E)],
      playerColorNames: ['Ruby', 'Sapphire'],
    ),
    PressThemeDef(
      id: 'ivory',
      name: 'Ivory Proof',
      bg: Color(0xFFEFE3C8),
      bgDeep: Color(0xFFD8CBA6),
      paper: Color(0xFFFBF6E9),
      paperDeep: Color(0xFFE9DCBC),
      accent: Color(0xFF9A7B1E),
      accentLight: Color(0xFFC9A227),
      accentDark: Color(0xFF6E5514),
      ink: Color(0xFF2A2118),
      muted: Color(0xFF9A8C72),
      correct: Color(0xFF2E7D32),
      present: Color(0xFFB26A00),
      absent: Color(0xFFB0B0B0),
      playerColors: [Color(0xFFA31621), Color(0xFF1D4E9E)],
      playerColorNames: ['Ruby', 'Sapphire'],
    ),
    PressThemeDef(
      id: 'emerald',
      name: 'Emerald Baize',
      bg: Color(0xFF123326),
      bgDeep: Color(0xFF0A2018),
      paper: Color(0xFFF1EAD6),
      paperDeep: Color(0xFFD6CCAC),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ink: Color(0xFF0F2A20),
      muted: Color(0xFF7A8A7E),
      correct: Color(0xFF1B8A4A),
      present: Color(0xFFE8A100),
      absent: Color(0xFF7E7E7E),
      playerColors: [Color(0xFFC0392B), Color(0xFFD4AC0D)],
      playerColorNames: ['Cinnabar', 'Ochre'],
    ),
    PressThemeDef(
      id: 'cherry',
      name: 'Cherry Press',
      bg: Color(0xFF4A1F14),
      bgDeep: Color(0xFF2B1009),
      paper: Color(0xFFF5E8D2),
      paperDeep: Color(0xFFDDC8A4),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      ink: Color(0xFF3A1608),
      muted: Color(0xFF9A7E63),
      correct: Color(0xFF2E7D32),
      present: Color(0xFFD89B00),
      absent: Color(0xFF8D8D8D),
      playerColors: [Color(0xFF1B7A4D), Color(0xFFD99A2B)],
      playerColorNames: ['Jade', 'Amber'],
    ),
    PressThemeDef(
      id: 'midnight',
      name: 'Midnight Bindery',
      bg: Color(0xFF1C2438),
      bgDeep: Color(0xFF101624),
      paper: Color(0xFFF2EEE4),
      paperDeep: Color(0xFFD8D2BC),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      ink: Color(0xFF1A2130),
      muted: Color(0xFF7A8296),
      correct: Color(0xFF2FA35C),
      present: Color(0xFFE0A83C),
      absent: Color(0xFF6E7488),
      playerColors: [Color(0xFFD64545), Color(0xFF3FB97F)],
      playerColorNames: ['Candle', 'Fern'],
    ),
    PressThemeDef(
      id: 'copper',
      name: 'Copperplate',
      bg: Color(0xFF33220F),
      bgDeep: Color(0xFF1E1307),
      paper: Color(0xFFF1E6CE),
      paperDeep: Color(0xFFD8C8A0),
      accent: Color(0xFFB87333),
      accentLight: Color(0xFFE09E5A),
      accentDark: Color(0xFF7E4F22),
      ink: Color(0xFF2E1D0A),
      muted: Color(0xFF9A7E58),
      correct: Color(0xFF2E7D32),
      present: Color(0xFFCA6F1E),
      absent: Color(0xFF8D8D8D),
      playerColors: [Color(0xFF1D4E9E), Color(0xFF1B7A4D)],
      playerColorNames: ['Steel', 'Leaf'],
    ),
    PressThemeDef(
      id: 'slate',
      name: 'Slate & Chalk',
      bg: Color(0xFF2E3440),
      bgDeep: Color(0xFF1A1E26),
      paper: Color(0xFFECEFF4),
      paperDeep: Color(0xFFD3D9E2),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ink: Color(0xFF232A36),
      muted: Color(0xFF7A8291),
      correct: Color(0xFF3E9B5F),
      present: Color(0xFFEBCB8B),
      absent: Color(0xFF6E7684),
      playerColors: [Color(0xFFBF616A), Color(0xFF5E81AC)],
      playerColorNames: ['Aurora', 'Frost'],
    ),
    PressThemeDef(
      id: 'teal',
      name: 'Teal Ink',
      bg: Color(0xFF0F3A3A),
      bgDeep: Color(0xFF081F1F),
      paper: Color(0xFFF0EDE2),
      paperDeep: Color(0xFFD6D0B8),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ink: Color(0xFF0C2626),
      muted: Color(0xFF6E8A86),
      correct: Color(0xFF1E9E57),
      present: Color(0xFFE8A100),
      absent: Color(0xFF6E7E7C),
      playerColors: [Color(0xFFC0392B), Color(0xFF8E44AD)],
      playerColorNames: ['Poppy', 'Plum'],
    ),
    PressThemeDef(
      id: 'porcelain',
      name: 'Porcelain Type',
      bg: Color(0xFFE8E0D0),
      bgDeep: Color(0xFFCFC2A8),
      paper: Color(0xFFFFFFFF),
      paperDeep: Color(0xFFE8ECF0),
      accent: Color(0xFF2E5A88),
      accentLight: Color(0xFF5E8AC0),
      accentDark: Color(0xFF1E3A5C),
      ink: Color(0xFF1E2A3A),
      muted: Color(0xFF8A96A8),
      correct: Color(0xFF2E7D32),
      present: Color(0xFFB26A00),
      absent: Color(0xFFB9C2CC),
      playerColors: [Color(0xFFC0392B), Color(0xFF1B7A4D)],
      playerColorNames: ['Cinnabar', 'Celadon'],
    ),
    PressThemeDef(
      id: 'crimson',
      name: 'Crimson Cloth',
      bg: Color(0xFF4A1420),
      bgDeep: Color(0xFF2A0A12),
      paper: Color(0xFFF5EBD6),
      paperDeep: Color(0xFFDCCFAE),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      ink: Color(0xFF3A0E18),
      muted: Color(0xFF9A7E7E),
      correct: Color(0xFF2E9E4F),
      present: Color(0xFFE8B400),
      absent: Color(0xFF8D7E7E),
      playerColors: [Color(0xFFD4AC0D), Color(0xFF2E86C1)],
      playerColorNames: ['Topaz', 'River'],
    ),
    PressThemeDef(
      id: 'ebony',
      name: 'Ebony & Silver',
      bg: Color(0xFF16161A),
      bgDeep: Color(0xFF0C0C0E),
      paper: Color(0xFFF2EEE4),
      paperDeep: Color(0xFFD6D0BC),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFF0F2F8),
      accentDark: Color(0xFF7E8698),
      ink: Color(0xFF141418),
      muted: Color(0xFF7E7E88),
      correct: Color(0xFF35B06A),
      present: Color(0xFFF5B041),
      absent: Color(0xFF5E5E66),
      playerColors: [Color(0xFFE74C3C), Color(0xFF3498DB)],
      playerColorNames: ['Flame', 'Sky'],
    ),
  ];

  static PressThemeDef byId(String id, {PressThemeDef? custom}) {
    if (id == 'custom') {
      return custom ?? all.first;
    }
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';
}

/// Letter tile + keyboard styles. 0-3 = FREE, 4+ = PRO.
/// Each style is a physical material: base gradient, edge color, radius.
class TileStyles {
  static const names = [
    'Oak Blocks',
    'Ivory Domino',
    'Brass Plate',
    'Slate Tablet',
    'Walnut Carved',
    'Porcelain',
    'Copper Stamp',
    'Leather Bound',
  ];
  static const descriptions = [
    'Honey-oak type blocks',
    'Cold-cast ivory dominoes',
    'Engraved brass plates',
    'Cut slate tablets',
    'Hand-carved walnut',
    'Glazed porcelain',
    'Copper press stamps',
    'Tooled leather tiles',
  ];

  /// Styles free players may use.
  static const freeCount = 4;
  static bool isPro(int index) => index >= freeCount;

  /// [light] → [dark] gradient of the unmarked tile face.
  static List<Color> base(int index, PressThemeDef t) {
    switch (index) {
      case 0:
        return [const Color(0xFFC89A5A), const Color(0xFF8A5E2A)];
      case 1:
        return [const Color(0xFFFFFEF8), const Color(0xFFEDE4CE)];
      case 2:
        return [const Color(0xFFE8CE7A), const Color(0xFFA8842A)];
      case 3:
        return [const Color(0xFF5A6577), const Color(0xFF303844)];
      case 4:
        return [const Color(0xFF7C4F2B), const Color(0xFF42260F)];
      case 5:
        return [const Color(0xFFFFFFFF), const Color(0xFFD8DEE6)];
      case 6:
        return [const Color(0xFFE09E5A), const Color(0xFF9A5A22)];
      case 7:
        return [const Color(0xFF7A4A2A), const Color(0xFF44260F)];
      default:
        return [const Color(0xFFC89A5A), const Color(0xFF8A5E2A)];
    }
  }

  /// Edge/bevel color for the unmarked tile face.
  static Color edge(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF6E4A1E);
      case 1:
        return const Color(0xFFC9BFA8);
      case 2:
        return const Color(0xFF8A6D1A);
      case 3:
        return const Color(0xFF1E242E);
      case 4:
        return const Color(0xFF2A1608);
      case 5:
        return const Color(0xFF8A9AAB);
      case 6:
        return const Color(0xFF6E3A12);
      case 7:
        return const Color(0xFF2E1808);
      default:
        return const Color(0xFF6E4A1E);
    }
  }

  /// Letter ink on the unmarked tile face.
  static Color ink(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF3A2408);
      case 1:
        return const Color(0xFF1A1A1A);
      case 2:
        return const Color(0xFF3A2A08);
      case 3:
        return const Color(0xFFF0EBDD);
      case 4:
        return const Color(0xFFF1E6CE);
      case 5:
        return const Color(0xFF1D4E9E);
      case 6:
        return const Color(0xFF2A1408);
      case 7:
        return const Color(0xFFF5EFE0);
      default:
        return const Color(0xFF3A2408);
    }
  }

  static double radius(int index) {
    switch (index) {
      case 1:
        return 14;
      case 5:
        return 14;
      case 2:
        return 6;
      case 6:
        return 4;
      default:
        return 10;
    }
  }
}
