import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/press_themes.dart';

/// Persisted settings + stats for Word Guess. Survives app restarts.
///
/// Stores: audio toggles, player names (pass-and-play slots), theme/tile
/// appearance choices (incl. custom theme colors), mode + difficulty,
/// Pro unlock state, and lifetime stats (streaks, wins, games).
class WordSettings extends ChangeNotifier {
  static const _kMusic = 'wordguess_music_on';
  static const _kSfx = 'wordguess_sfx_on';
  static const _kVolume = 'wordguess_volume';
  static const _kDifficulty = 'wordguess_difficulty'; // 0 easy, 1 classic, 2 master
  static const _kMode = 'wordguess_mode'; // 0 daily, 1 endless, 2 versus
  static const _kNamesLegacy = 'wordguess_player_names'; // legacy unordered key
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so a
  /// StringList scrambles name order on every app restart. Never use a
  /// StringList for ordered data on Android.
  static const _kNamesJson = 'wordguess_player_names_json';
  static const _kTheme = 'wordguess_theme_id';
  static const _kTileStyle = 'wordguess_tile_style';
  static const _kIsPro = 'wordguess_is_pro';
  static const _kStreak = 'wordguess_streak';
  static const _kBestStreak = 'wordguess_best_streak';
  static const _kGames = 'wordguess_games_played';
  static const _kRoundsWon = 'wordguess_rounds_won';
  static const _kDailyKey = 'wordguess_daily_key'; // yyyy-mm-dd of last counted daily
  static const _kCustomPrefix = 'wordguess_custom_';

  static const defaultNames = ['Lexi', 'Wordy'];

  /// Encode the player names as one JSON string (order-preserving).
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i % defaultNames.length] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == 2) {
        return [for (int i = 0; i < 2; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int difficulty = 1; // 0 = Sprout (4 letters), 1 = Classic (5), 2 = Master (6, Pro)
  int mode = 0; // 0 = Daily, 1 = Endless, 2 = Versus (pass-and-play)
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'classic';
  int tileStyle = 0;
  bool isPro = false;
  int streak = 0;
  int bestStreak = 0;
  int gamesPlayed = 0;
  int roundsWon = 0;
  String dailyKey = ''; // last daily that counted toward the streak

  /// Custom theme colors (ARGB ints). Defaults mirror Printshop Oak.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'bg': 0xFF2E1F14,
    'bgDeep': 0xFF1A1109,
    'paper': 0xFFF1E6CE,
    'paperDeep': 0xFFDCCDA9,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8CE7A,
    'accentDark': 0xFF8A6D1A,
    'ink': 0xFF2E1F14,
    'muted': 0xFF8A7961,
    'correct': 0xFF2E7D32,
    'present': 0xFFE8A100,
    'absent': 0xFF8D8D8D,
    'pc0': 0xFFA31621,
    'pc1': 0xFF1D4E9E,
  };

  /// Builds the user-designed custom theme from stored colors.
  PressThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return PressThemeDef(
      id: 'custom',
      name: 'My Creation',
      bg: c('bg'),
      bgDeep: c('bgDeep'),
      paper: c('paper'),
      paperDeep: c('paperDeep'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      ink: c('ink'),
      muted: c('muted'),
      correct: c('correct'),
      present: c('present'),
      absent: c('absent'),
      playerColors: [c('pc0'), c('pc1')],
      playerColorNames: const ['One', 'Two'],
    );
  }

  SharedPreferences? _prefs;

  int get wordLen => [4, 5, 6][difficulty.clamp(0, 2)];
  int get maxTries => [7, 6, 6][difficulty.clamp(0, 2)];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    mode = (p.getInt(_kMode) ?? 0).clamp(0, 2);
    // Player names: prefer the order-safe JSON key. Fall back to the legacy
    // StringList key once (one-time migration); it may already be scrambled
    // on Android, which is exactly the bug this replaces.
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNamesLegacy);
      playerNames = (legacy != null && legacy.length == 2)
          ? [for (int i = 0; i < 2; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'classic';
    tileStyle = (p.getInt(_kTileStyle) ?? 0).clamp(0, TileStyles.names.length - 1);
    isPro = p.getBool(_kIsPro) ?? false;
    streak = p.getInt(_kStreak) ?? 0;
    bestStreak = p.getInt(_kBestStreak) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    roundsWon = p.getInt(_kRoundsWon) ?? 0;
    dailyKey = p.getString(_kDailyKey) ?? '';
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kDifficulty, difficulty);
    await p.setInt(_kMode, mode);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNamesLegacy); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setInt(_kTileStyle, tileStyle);
    await p.setBool(_kIsPro, isPro);
    await p.setInt(_kStreak, streak);
    await p.setInt(_kBestStreak, bestStreak);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kRoundsWon, roundsWon);
    await p.setString(_kDailyKey, dailyKey);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || PressThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (TileStyles.isPro(tileStyle)) {
      tileStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    if (!isPro && v > 1) return; // Master is a Pro feature
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setMode(int v) async {
    mode = v.clamp(0, 2);
    notifyListeners();
    await _save();
  }

  /// Live name save: called on EVERY keystroke so no rename is ever lost.
  Future<void> savePlayerNameLive(int index, String name) async {
    if (index < 0 || index > 1) return;
    playerNames[index] = name; // raw text while typing
    await _save();
  }

  /// Commit on focus loss / keyboard done: trim and fall back to defaults.
  Future<void> commitPlayerName(int index, String name) async {
    if (index < 0 || index > 1) return;
    playerNames[index] = _cleanName(index, name);
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || PressThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setTileStyle(int v) async {
    v = v.clamp(0, TileStyles.names.length - 1);
    if (!isPro && TileStyles.isPro(v)) return;
    tileStyle = v;
    notifyListeners();
    await _save();
  }

  /// Today's daily key for the current difficulty's word length.
  String get todayDailyKey {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return '${d.year}-${d.month}-${d.day}-$wordLen';
  }

  /// Record one finished turn. [counts] is false for a replayed daily.
  Future<void> recordTurn({required bool solved, required bool counts}) async {
    gamesPlayed++;
    if (solved) {
      roundsWon++;
      if (counts) {
        streak++;
        if (streak > bestStreak) bestStreak = streak;
      }
    } else if (counts) {
      streak = 0;
    }
    notifyListeners();
    await _save();
  }

  /// Mark today's daily as counted (call after a counted daily turn).
  Future<void> claimDaily() async {
    dailyKey = todayDailyKey;
    notifyListeners();
    await _save();
  }
}
