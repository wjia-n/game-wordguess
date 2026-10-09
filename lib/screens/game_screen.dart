import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/word_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/letterpress.dart';
import '../theme/press_themes.dart';

/// Word Guess gameplay: letterpress tiles, flip-reveal animations,
/// round timer, streak display, and a physical keyboard.
class GameScreen extends StatefulWidget {
  final WordEngine engine;
  final WordAudio audio;
  final WordSettings settings;
  const GameScreen({
    super.key,
    required this.engine,
    required this.audio,
    required this.settings,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  WordEngine get _e => widget.engine;
  WordAudio get _audio => widget.audio;
  WordSettings get _s => widget.settings;

  final Map<String, GlobalKey<_FlipTileState>> _flipKeys = {};
  late final AnimationController _shake;
  int _lastInvalidNonce = 0;
  bool _claimed = false; // daily already counted once
  late bool _counts; // this run counts toward streak/stats

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _counts = _e.countsForStats;
    _lastInvalidNonce = _e.invalidNonce;
    _e.onFlip = (row, col, prev) {
      _audio.flip();
      _flipKeys['$row-$col']?.currentState?.flip(prev);
    };
    _e.onTurnSettled = _onTurnSettled;
    _e.addListener(_onEngine);
    _audio.startGameMusic();
    _e.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _e.setPaused(true);
    }
  }

  void _onEngine() {
    if (!mounted) return;
    if (_e.invalidNonce != _lastInvalidNonce) {
      _lastInvalidNonce = _e.invalidNonce;
      _audio.invalid();
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _e.removeListener(_onEngine);
    _shake.dispose();
    _e.dispose();
    super.dispose();
  }

  void _onTurnSettled(TurnResult r) {
    // Streaks are a solo achievement: Daily (first attempt of the day only)
    // and Endless count; Versus records games/rounds but never the streak.
    final isDaily = _e.mode == PlayMode.daily;
    final isSolo = !(_e.mode == PlayMode.versus);
    final counts = isSolo && (isDaily ? (_counts && !_claimed) : true);
    if (isDaily && counts) {
      _claimed = true;
      _s.claimDaily();
    }
    _s.recordTurn(solved: r.solved, counts: counts);
    if (r.timedOut) {
      _audio.timeout();
    } else if (r.solved) {
      _audio.roundWin();
      if (_s.streak > 0 && _s.streak % 5 == 0) _audio.streak();
    } else {
      _audio.lose();
    }
  }

  void _press(String k) {
    if (k == 'ENTER') {
      _e.type('ENTER');
    } else if (k == 'BACK') {
      if (_e.type('BACK')) _audio.type();
    } else {
      if (_e.type(k)) _audio.type();
    }
  }

  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {}
  }

  void _shareResult() {
    _audio.click();
    final total = _e.scores.fold<int>(0, (a, b) => a + b);
    // ignore: deprecated_member_use
    Share.share(
      'I scored $total points in Word Guess! 🔥 Streak: ${_s.streak} — '
      'https://play.google.com/store/apps/details?id=com.gameswajiha.wordguess',
    );
  }

  void _quit() {
    _audio.click();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = PressThemes.byId(_s.themeId, custom: _s.customTheme);
    return PaperBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _e,
            builder: (_, _) => Stack(
              children: [
                Column(
                  children: [
                    _header(t),
                    Expanded(child: Center(child: _boardArea(t))),
                    _keyboard(t),
                    const SizedBox(height: 8),
                  ],
                ),
                if (_e.paused &&
                    (_e.phase == WordPhase.playing ||
                        _e.phase == WordPhase.revealing))
                  _pauseOverlay(t),
                if (_e.phase == WordPhase.roundSettled)
                  _roundCard(t),
                if (_e.phase == WordPhase.gameOver)
                  _gameOverCard(t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _header(PressThemeDef t) {
    final mm = (_e.secondsLeft ~/ 60).toString();
    final ss = (_e.secondsLeft % 60).toString().padLeft(2, '0');
    final lowTime = _e.secondsLeft <= 30;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.pause, color: t.accentLight),
            onPressed: () {
              if (_e.phase != WordPhase.playing &&
                  _e.phase != WordPhase.revealing) {
                return;
              }
              _audio.click();
              _e.setPaused(true);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_e.roundLabel,
                    style: Press.label(13, theme: t),
                    overflow: TextOverflow.ellipsis),
                if (_e.isVersus)
                  Text(
                    _e.playerNames
                        .asMap()
                        .entries
                        .map((e2) =>
                            '${_s.playerNames[e2.key]}: ${_e.scores[e2.key]}')
                        .join('   •   '),
                    style: Press.body(12,
                        theme: t, color: t.paper.withValues(alpha: 0.7)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                  color: t.accent.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Text('🔥 ${_s.streak}',
                style: Press.label(14, theme: t)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: lowTime
                  ? const Color(0xFFA31621).withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                  color: lowTime
                      ? const Color(0xFFE08A8A)
                      : t.accent.withValues(alpha: 0.5),
                  width: 1.5),
            ),
            child: Text('⏱ $mm:$ss',
                style: Press.label(14,
                    theme: t,
                    color: lowTime
                        ? const Color(0xFFFFD9D9)
                        : t.paper)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- board
  Widget _boardArea(PressThemeDef t) {
    return LayoutBuilder(builder: (_, box) {
      final len = _e.wordLen;
      final tries = _e.maxTries;
      const gap = 6.0;
      final tile = ((box.maxWidth - gap * (len - 1)) / len)
          .clamp(0.0, (box.maxHeight - gap * (tries - 1)) / tries);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < tries; r++)
            Padding(
              padding: EdgeInsets.only(bottom: r == tries - 1 ? 0 : gap),
              child: r == _e.guesses.length && _e.phase == WordPhase.playing
                  ? _shakeRow(t, tile, r)
                  : _row(t, tile, r),
            ),
        ],
      );
    });
  }

  Widget _shakeRow(PressThemeDef t, double tile, int r) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) {
        final dx = 10 * (1 - _shake.value) * sin(_shake.value * 6 * 3.14159);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: _row(t, tile, r),
    );
  }

  Widget _row(PressThemeDef t, double tile, int r) {
    final len = _e.wordLen;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var c = 0; c < len; c++)
          Padding(
            padding: EdgeInsets.only(right: c == len - 1 ? 0 : 6),
            child: _tile(t, tile, r, c),
          ),
      ],
    );
  }

  Widget _tile(PressThemeDef t, double tile, int r, int c) {
    String letter = '';
    Mark mark = Mark.none;
    if (r < _e.guesses.length) {
      letter = _e.guesses[r][c];
      mark = _e.marks[r][c];
      final key = _flipKeys.putIfAbsent(
          '$r-$c', () => GlobalKey<_FlipTileState>());
      return _FlipTile(
        key: key,
        size: tile,
        letter: letter,
        mark: mark,
        theme: t,
        style: _s.tileStyle,
      );
    }
    if (r == _e.guesses.length && c < _e.input.length) {
      letter = _e.input[c];
    }
    final filled = letter.isNotEmpty;
    final radius = TileStyles.radius(_s.tileStyle);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: tile,
      height: tile,
      transform: Matrix4.identity()..scale(filled ? 1.06 : 1.0),
      alignment: Alignment.center,
      decoration: tileDecoration(t, _s.tileStyle, Mark.none, radius).copyWith(
        border: Border.all(
          color: filled
              ? t.accent.withValues(alpha: 0.7)
              : TileStyles.edge(_s.tileStyle),
          width: 2,
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: tile * 0.46,
          fontWeight: FontWeight.w800,
          color: tileInk(t, _s.tileStyle, Mark.none),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- keyboard
  Widget _keyboard(PressThemeDef t) {
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

  Widget _key(PressThemeDef t, String k,
      {required int flex, required String label}) {
    final mark = _e.keyMarks[k] ?? Mark.none;
    final used = mark != Mark.none;
    final radius = TileStyles.radius(_s.tileStyle);
    Color bgTop, bgBottom, edge, ink;
    if (used) {
      final c = _markColorOf(mark, t);
      bgTop = c.withValues(alpha: 0.95);
      bgBottom = c;
      edge = t.bgDeep;
      ink = mark == Mark.absent ? t.paper.withValues(alpha: 0.6) : Colors.white;
    } else {
      final base = TileStyles.base(_s.tileStyle, t);
      bgTop = base[0];
      bgBottom = base[1];
      edge = TileStyles.edge(_s.tileStyle);
      ink = TileStyles.ink(_s.tileStyle);
    }
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: GestureDetector(
          onTap: () => _press(k),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius * 0.7),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgTop, bgBottom],
              ),
              border: Border.all(color: edge, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  offset: const Offset(0, 3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: k.length > 1 ? 15 : 19,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _markColorOf(Mark m, PressThemeDef t) {
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

  // ---------------------------------------------------------------- overlays
  Widget _dim(PressThemeDef t, Widget child) {
    return Container(
      color: Colors.black.withValues(alpha: 0.62),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: child,
    );
  }

  Widget _pauseOverlay(PressThemeDef t) {
    return _dim(
      t,
      Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
              colors: [t.bgDeep, t.bg],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          border: Border.all(color: t.accent, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Paused', style: Press.display(30, theme: t)),
            const SizedBox(height: 6),
            Text('The press is holding your place.',
                style: Press.body(14, theme: t)),
            const SizedBox(height: 20),
            PressButton(
              label: '▶  Resume',
              theme: t,
              width: 220,
              onTap: () {
                _audio.click();
                _e.setPaused(false);
              },
            ),
            const SizedBox(height: 10),
            PressButton(
              label: '↻  New word',
              theme: t,
              width: 220,
              fontSize: 16,
              onTap: () {
                _audio.click();
                _e.restartTurn();
              },
            ),
            const SizedBox(height: 10),
            PressButton(
              label: '✕  Quit to menu',
              theme: t,
              width: 220,
              fontSize: 16,
              onTap: _quit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundCard(PressThemeDef t) {
    final r = _e.history.isEmpty ? null : _e.history.last;
    final solved = r?.solved ?? false;
    final timedOut = r?.timedOut ?? false;
    final nextLabel = _e.mode == PlayMode.versus
        ? (_isLastTurn()
            ? 'See results ▶'
            : 'Hand to ${_nextPlayerName()} ▶')
        : _e.mode == PlayMode.daily
            ? 'Done ▶'
            : 'Next word ▶';
    final lastWord = r?.word ?? '';
    return _dim(
      t,
      Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
              colors: [t.bgDeep, t.bg],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          border: Border.all(color: t.accent, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              solved
                  ? 'Brilliant! 🎉'
                  : timedOut
                      ? "Time's up! ⏰"
                      : 'So close! 💪',
              style: Press.display(28, theme: t),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              solved
                  ? 'The word was $lastWord — ${r!.guessesUsed} ${r.guessesUsed == 1 ? 'try' : 'tries'}.'
                  : 'The word was $lastWord.',
              style: Press.body(15, theme: t),
              textAlign: TextAlign.center,
            ),
            if (solved) ...[
              const SizedBox(height: 6),
              Text('+${r!.points} points',
                  style: Press.label(18, theme: t)),
            ],
            const SizedBox(height: 6),
            Text('🔥 Streak: ${_s.streak}',
                style: Press.body(14, theme: t)),
            const SizedBox(height: 18),
            PressButton(
              label: nextLabel,
              theme: t,
              width: 240,
              onTap: () {
                _audio.click();
                _e.nextTurn();
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isLastTurn() {
    if (!_e.isVersus) return false;
    return _e.round == _e.roundsPerPlayer &&
        _e.playerIdx == _e.playerNames.length - 1;
  }

  String _nextPlayerName() {
    var idx = _e.playerIdx + 1;
    if (idx >= _e.playerNames.length) idx = 0;
    return _s.playerNames[idx];
  }

  Widget _gameOverCard(PressThemeDef t) {
    final total = _e.scores.fold<int>(0, (a, b) => a + b);
    String headline;
    String subline;
    if (_e.isVersus) {
      final w = _e.scores[0] == _e.scores[1]
          ? -1
          : (_e.scores[0] > _e.scores[1] ? 0 : 1);
      headline = w == -1 ? "It's a tie! 🤝" : '${_s.playerNames[w]} wins! 🏆';
      subline =
          '${_s.playerNames[0]}: ${_e.scores[0]} pts   •   ${_s.playerNames[1]}: ${_e.scores[1]} pts';
    } else {
      headline = 'Run complete! 🎉';
      subline =
          '${_e.wordsSolvedThisRun} ${_e.wordsSolvedThisRun == 1 ? 'word' : 'words'} solved · $total points · 🔥 streak ${_s.streak}';
    }
    return _dim(
      t,
      Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
              colors: [t.bgDeep, t.bg],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          border: Border.all(color: t.accent, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(headline,
                style: Press.display(28, theme: t),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(subline,
                style: Press.body(15, theme: t), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            PressButton(
              label: '▶  Play again',
              theme: t,
              width: 240,
              onTap: () {
                _audio.click();
                _newRun();
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _smallBtn(t, Icons.share, 'Share', _shareResult),
                const SizedBox(width: 14),
                _smallBtn(t, Icons.star_rate, 'Rate', _requestReview),
                const SizedBox(width: 14),
                _smallBtn(t, Icons.home, 'Menu', _quit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallBtn(
      PressThemeDef t, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.bgDeep, t.bg],
              ),
              border: Border.all(color: t.accent, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: t.accentLight, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: Press.label(12, theme: t)),
        ],
      ),
    );
  }

  void _newRun() {
    // Build a fresh engine for a new run with the same setup; the old
    // engine (and this state) is disposed by the route replacement.
    final fresh = WordEngine(
      mode: _e.mode,
      wordLen: _e.wordLen,
      maxTries: _e.maxTries,
      playerNames: _e.playerNames,
      countsForStats: _e.countsForStats,
      onTurnSettled: _onTurnSettled,
      roundsPerPlayer: _e.roundsPerPlayer,
    );
    _flipKeys.clear();
    _claimed = false;
    _counts = fresh.countsForStats;
    _lastInvalidNonce = 0;
    fresh.onFlip = (row, col, prev) {
      _audio.flip();
      _flipKeys['$row-$col']?.currentState?.flip(prev);
    };
    fresh.addListener(_onEngine);
    // Swap engines: GameScreen holds the engine as a widget field, so push
    // a replacement instead of mutating the widget.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          engine: fresh,
          audio: _audio,
          settings: _s,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// A single letter tile that flips in 3D when its letter is revealed.
class _FlipTile extends StatefulWidget {
  final double size;
  final String letter;
  final Mark mark;
  final PressThemeDef theme;
  final int style;
  const _FlipTile({
    super.key,
    required this.size,
    required this.letter,
    required this.mark,
    required this.theme,
    required this.style,
  });

  @override
  State<_FlipTile> createState() => _FlipTileState();
}

class _FlipTileState extends State<_FlipTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Mark _front = Mark.none;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  /// Engine calls this right after the mark flipped: [prev] is the face
  /// showing for the first half of the rotation.
  void flip(Mark prev) {
    _front = prev;
    if (!_c.isAnimating) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final angle = _c.value * 3.14159;
        final showFront = angle < 3.14159 / 2;
        final face = showFront ? _front : widget.mark;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(angle),
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: tileDecoration(widget.theme, widget.style, face,
                TileStyles.radius(widget.style)),
            child: Text(
              widget.letter,
              style: TextStyle(
                fontSize: widget.size * 0.46,
                fontWeight: FontWeight.w800,
                color: tileInk(widget.theme, widget.style, face),
              ),
            ),
          ),
        );
      },
    );
  }
}
