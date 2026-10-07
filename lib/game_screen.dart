import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Word Guess — Wordle-style solo game.
/// 3 rounds per run: round 1 is the daily word (date-seeded), rounds 2-3 random.
class WordGuessScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const WordGuessScreen({super.key, required this.players, required this.callbacks});

  @override
  State<WordGuessScreen> createState() => _WordGuessScreenState();
}

enum _Mark { none, correct, present, absent }

class _WordGuessScreenState extends State<WordGuessScreen> {
  static const _words = [
    'APPLE', 'HOUSE', 'TRAIN', 'MONEY', 'WATER', 'LIGHT', 'MUSIC', 'DANCE', 'SMILE', 'HEART',
    'OCEAN', 'FLAME', 'GRAPE', 'MAGIC', 'NIGHT', 'PIANO', 'QUEEN', 'RADIO', 'SNAKE', 'TIGER',
    'BREAD', 'CHAIR', 'CLOUD', 'DREAM', 'EAGLE', 'FROST', 'GHOST', 'HONEY', 'IVORY', 'JELLY',
    'KNIFE', 'LEMON', 'MANGO', 'NURSE', 'ONION', 'PARTY', 'QUILT', 'RIVER', 'STONE', 'TABLE',
    'UNCLE', 'VIVID', 'WHALE', 'YOUTH', 'ZEBRA', 'ANGEL', 'BEACH', 'CANDY', 'DRAMA', 'ELBOW',
    'FOCUS', 'GIANT', 'HORSE', 'INPUT', 'JOKER', 'KNEEL', 'LAUGH', 'METAL', 'NOVEL', 'PILOT',
  ];
  static const _rounds = 3;
  static const _tries = 6;

  late String _target;
  bool _daily = true;
  int _round = 1;
  int _solved = 0;
  final List<String> _guesses = [];
  final List<List<_Mark>> _marks = [];
  final Map<String, _Mark> _keyMarks = {};
  String _input = '';
  bool _lock = false; // true while letters are revealing
  bool _roundOver = false;
  bool _over = false;

  Player get _me => widget.players.first;

  @override
  void initState() {
    super.initState();
    _target = _dailyWord();
  }

  String _dailyWord() {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 86400000;
    return _words[days % _words.length];
  }

  String _randomWord() {
    final w = (_words.toList()..shuffle()).first;
    return w == _target ? _words[(_words.indexOf(w) + 7) % _words.length] : w;
  }

  void _switchMode(bool daily) {
    if (_lock || _roundOver || _guesses.isNotEmpty || _input.isNotEmpty) return;
    setState(() {
      _daily = daily;
      _target = daily ? _dailyWord() : _randomWord();
    });
    Sfx.tap();
  }

  void _press(String k) {
    if (_lock || _roundOver || _over) return;
    if (k == 'ENTER') {
      _submit();
    } else if (k == 'BACK') {
      if (_input.isNotEmpty) {
        setState(() => _input = _input.substring(0, _input.length - 1));
        Sfx.tap();
      }
    } else if (_input.length < 5) {
      setState(() => _input += k);
      Sfx.tap();
    }
  }

  void _submit() {
    if (_input.length != 5) return;
    final guess = _input;
    setState(() {
      _input = '';
      _guesses.add(guess);
      _marks.add(List.filled(5, _Mark.none));
      _lock = true;
    });
    Sfx.move();
    final fb = _feedback(guess, _target);
    for (var i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: 140 * i + 60), () {
        if (!mounted) return;
        setState(() => _marks.last[i] = fb[i]);
        Sfx.click();
        _absorbKey(guess[i], fb[i]);
      });
    }
    Future.delayed(const Duration(milliseconds: 140 * 5 + 200), () {
      if (!mounted) return;
      setState(() => _lock = false);
      if (guess == _target) {
        _wonRound();
      } else if (_guesses.length >= _tries) {
        _lostRound();
      }
    });
  }

  List<_Mark> _feedback(String guess, String target) {
    final res = List.filled(5, _Mark.absent);
    final counts = <String, int>{};
    for (final c in target.split('')) {
      counts[c] = (counts[c] ?? 0) + 1;
    }
    for (var i = 0; i < 5; i++) {
      if (guess[i] == target[i]) {
        res[i] = _Mark.correct;
        counts[guess[i]] = counts[guess[i]]! - 1;
      }
    }
    for (var i = 0; i < 5; i++) {
      if (res[i] == _Mark.correct) continue;
      if ((counts[guess[i]] ?? 0) > 0) {
        res[i] = _Mark.present;
        counts[guess[i]] = counts[guess[i]]! - 1;
      }
    }
    return res;
  }

  void _absorbKey(String letter, _Mark mark) {
    final rank = {_Mark.none: 0, _Mark.absent: 1, _Mark.present: 2, _Mark.correct: 3};
    final cur = _keyMarks[letter] ?? _Mark.none;
    if (rank[mark]! > rank[cur]!) {
      setState(() => _keyMarks[letter] = mark);
    }
  }

  void _wonRound() {
    setState(() => _roundOver = true);
    _me.score += 1;
    _solved += 1;
    widget.callbacks.refreshHud();
    Sfx.win();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      _nextRound();
    });
  }

  void _lostRound() {
    setState(() => _roundOver = true);
    Sfx.lose();
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      _nextRound();
    });
  }

  void _nextRound() {
    if (_round >= _rounds) {
      _finishRun();
      return;
    }
    setState(() {
      _round++;
      _daily = false; // rounds 2+ default to random
      _target = _randomWord();
      _guesses.clear();
      _marks.clear();
      _keyMarks.clear();
      _input = '';
      _lock = false;
      _roundOver = false;
    });
  }

  void _finishRun() {
    if (_over) return;
    _over = true;
    widget.callbacks.finish(
      headline: 'You solved $_solved/$_rounds words! 🔥',
      subline: _solved == 3
          ? 'PERFECT run! Your brain deserves a trophy. 🏆'
          : _solved == 2
              ? 'So close to perfect — the daily word will get you next time! 💪'
              : _solved == 1
                  ? 'One in the bag! Warm those word muscles up. 🌱'
                  : 'Tough run! Every master was once a beginner. 🍀',
    );
  }

  Color _markColor(_Mark m, GameTheme t) {
    switch (m) {
      case _Mark.correct:
        return const Color(0xFF43A047); // green: right spot
      case _Mark.present:
        return const Color(0xFFE8A100); // amber: wrong spot
      case _Mark.absent:
        return t.muted; // grey: not in word
      case _Mark.none:
        return t.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Round $_round/$_rounds',
                  style: TextStyle(color: t.text, fontWeight: FontWeight.w800, fontSize: 15)),
              Row(
                children: [
                  _modeChip(t, '📅 Daily', true),
                  const SizedBox(width: 8),
                  _modeChip(t, '🎲 Random', false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: Center(child: _board(t))),
          if (_roundOver)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _guesses.isNotEmpty && _guesses.last == _target
                    ? 'Brilliant! 🎉'
                    : 'The word was $_target 😅',
                style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          _keyboard(t),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _modeChip(GameTheme t, String label, bool daily) {
    final active = _daily == daily;
    final locked = _lock || _roundOver || _guesses.isNotEmpty || _input.isNotEmpty;
    return GestureDetector(
      onTap: locked ? null : () => _switchMode(daily),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? t.primary : t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? Colors.transparent : t.primary.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : (locked ? t.muted : t.text),
            )),
      ),
    );
  }

  Widget _board(GameTheme t) {
    return AspectRatio(
      aspectRatio: 5 / 6.4,
      child: Column(
        children: [
          for (var r = 0; r < _tries; r++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    for (var c = 0; c < 5; c++) Expanded(child: _tile(t, r, c)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(GameTheme t, int r, int c) {
    String letter = '';
    _Mark mark = _Mark.none;
    if (r < _guesses.length) {
      letter = _guesses[r][c];
      mark = _marks[r][c];
    } else if (r == _guesses.length && c < _input.length) {
      letter = _input[c];
    }
    final filled = letter.isNotEmpty;
    final revealed = mark != _Mark.none;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: revealed ? Curves.elasticOut : Curves.easeOut,
        transform: Matrix4.identity()
          ..scaleByDouble(revealed ? 1.0 : (filled ? 1.06 : 1.0),
              revealed ? 1.0 : (filled ? 1.06 : 1.0), 1, 1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: revealed ? _markColor(mark, t) : t.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: revealed
                ? Colors.transparent
                : filled
                    ? t.primary.withValues(alpha: 0.6)
                    : t.muted.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: revealed && mark != _Mark.absent ? Colors.white : t.text,
          ),
        ),
      ),
    );
  }

  Widget _keyboard(GameTheme t) {
    const rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];
    return Column(
      children: [
        for (var ri = 0; ri < rows.length; ri++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                if (ri == 2) _key(t, 'ENTER', flex: 2, label: '⏎'),
                for (final l in rows[ri].split('')) _key(t, l, flex: 1, label: l),
                if (ri == 2) _key(t, 'BACK', flex: 2, label: '⌫'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _key(GameTheme t, String k, {required int flex, required String label}) {
    final mark = _keyMarks[k] ?? _Mark.none;
    final used = mark != _Mark.none;
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: GestureDetector(
          onTap: () => _press(k),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: used ? _markColor(mark, t) : t.primary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: k.length > 1 ? 15 : 18,
                fontWeight: FontWeight.w800,
                color: used && mark != _Mark.absent ? Colors.white : (used ? t.text : Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
