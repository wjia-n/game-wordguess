import 'dart:async';
import 'package:flutter/foundation.dart';
import 'word_lists.dart';

/// Phases owned by the engine (never by UI timers).
enum WordPhase { idle, playing, revealing, roundSettled, gameOver }

/// Per-letter feedback after a guess is revealed.
enum Mark { none, correct, present, absent }

/// daily: one date-seeded word per difficulty.
/// endless: random words until you fail or quit.
/// versus: pass-and-play, each player gets their own word per round.
enum PlayMode { daily, endless, versus }

/// Result of one finished turn (one word for one player).
class TurnResult {
  final int playerIdx;
  final String word;
  final bool solved;
  final bool timedOut;
  final int guessesUsed;
  final int points;
  final int scoreAfter;
  const TurnResult({
    required this.playerIdx,
    required this.word,
    required this.solved,
    required this.timedOut,
    required this.guessesUsed,
    required this.points,
    required this.scoreAfter,
  });
}

/// Word Guess engine — the single owner of all game state.
///
/// The engine owns the turn state machine AND all of its timers:
/// - the reveal pipeline runs on engine timers (one tick per letter),
/// - the round countdown runs on an engine timer,
/// - a watchdog timer recovers any phase found without a live timer.
///
/// Stuck states are impossible by construction: every phase has a legal
/// forward action, and the watchdog force-settles a reveal that overruns
/// its deadline or forfeits a turn whose clock hit zero.
class WordEngine extends ChangeNotifier {
  // ------------------------------------------------------------- config
  final PlayMode mode;
  final int wordLen;
  final int maxTries;
  final int roundSeconds;
  final int roundsPerPlayer;
  final List<String> playerNames;
  final bool countsForStats;

  /// Called exactly once per finished turn (solved or failed).
  /// Assigned by the game screen (non-final so screens can wire it up).
  void Function(TurnResult result)? onTurnSettled;

  /// UI flip-animation hook: the engine has already set marks[row][col]
  /// when it fires; [prev] is the mark before this reveal (always none).
  void Function(int row, int col, Mark prev)? onFlip;

  WordEngine({
    required this.mode,
    required this.wordLen,
    required this.maxTries,
    required this.playerNames,
    required this.countsForStats,
    this.onTurnSettled,
    this.roundSeconds = 180,
    this.roundsPerPlayer = 3,
  });

  // -------------------------------------------------------------- state
  WordPhase phase = WordPhase.idle;
  String target = '';
  final List<String> guesses = [];
  final List<List<Mark>> marks = [];
  final Map<String, Mark> keyMarks = {};
  String input = '';
  int secondsLeft = 0;
  int round = 1; // versus round number (1..roundsPerPlayer)
  int playerIdx = 0; // current player in versus
  final List<int> scores = [];
  final List<TurnResult> history = [];
  bool paused = false;
  int invalidNonce = 0; // bumped on every invalid submit; UI shakes on change
  int wordsSolvedThisRun = 0;

  bool get isVersus => mode == PlayMode.versus;
  String get currentPlayerName =>
      playerNames[playerIdx.clamp(0, playerNames.length - 1)];
  String get roundLabel =>
      isVersus ? 'Round $round/$roundsPerPlayer · $currentPlayerName' : 'Word ${history.length + 1}';

  // ------------------------------------------------------------- timers
  Timer? _revealTimer;
  Timer? _clockTimer;
  Timer? _watchdog;
  DateTime _revealDeadline = DateTime.fromMillisecondsSinceEpoch(0);
  List<Mark> _fb = [];
  int _revealIndex = 0;
  String _lastWord = '';
  bool _started = false;
  bool _disposed = false;
  DateTime? _pauseStart;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    scores
      ..clear()
      ..addAll(List.filled(playerNames.length, 0));
    history.clear();
    round = 1;
    playerIdx = 0;
    wordsSolvedThisRun = 0;
    _lastWord = '';
    _watchdog = Timer.periodic(const Duration(milliseconds: 500), _watchdogTick);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), _clockTick);
    _beginTurn();
  }

  void _beginTurn() {
    target = _pickWord();
    guesses.clear();
    marks.clear();
    keyMarks.clear();
    input = '';
    secondsLeft = roundSeconds;
    _revealIndex = 0;
    paused = false;
    _setPhase(WordPhase.playing);
  }

  String _pickWord() {
    String w;
    if (mode == PlayMode.daily && playerIdx == 0 && history.isEmpty) {
      w = WordLists.dailyWord(wordLen, DateTime.now());
    } else {
      w = WordLists.randomWord(wordLen, _lastWord);
    }
    _lastWord = w;
    return w;
  }

  // -------------------------------------------------------------- input
  /// Returns true when the keypress was accepted.
  bool type(String k) {
    if (_disposed || phase != WordPhase.playing || paused) return false;
    if (k == 'ENTER') {
      submit();
      return true;
    }
    if (k == 'BACK') {
      if (input.isNotEmpty) {
        input = input.substring(0, input.length - 1);
        _notify();
        return true;
      }
      return false;
    }
    if (input.length < wordLen && k.length == 1) {
      input += k;
      _notify();
      return true;
    }
    return false;
  }

  /// Submits the current input. Short guesses are rejected with an
  /// [invalidNonce] bump (the UI shakes + plays the invalid sound).
  void submit() {
    if (_disposed || phase != WordPhase.playing || paused) return;
    if (input.length != wordLen) {
      invalidNonce++;
      _notify();
      return;
    }
    final guess = input;
    input = '';
    guesses.add(guess);
    marks.add(List.filled(wordLen, Mark.none));
    _fb = _feedback(guess, target);
    _revealIndex = 0;
    _setPhase(WordPhase.revealing);
    // Deadline: one tick per letter plus a generous watchdog margin.
    _revealDeadline =
        DateTime.now().add(Duration(milliseconds: wordLen * 400 + 2500));
    _revealTimer?.cancel();
    _revealTimer =
        Timer.periodic(const Duration(milliseconds: 400), _revealTick);
  }

  void _revealTick(Timer t) {
    if (_disposed) return;
    if (paused) return; // frozen; watchdog also skips while paused
    if (phase != WordPhase.revealing) {
      t.cancel();
      return;
    }
    if (_revealIndex >= wordLen) {
      t.cancel();
      _settleReveal();
      return;
    }
    final row = guesses.length - 1;
    marks[row][_revealIndex] = _fb[_revealIndex];
    _absorbKey(guesses[row][_revealIndex], _fb[_revealIndex]);
    final col = _revealIndex;
    _revealIndex++;
    _notify();
    onFlip?.call(row, col, Mark.none);
  }

  void _settleReveal() {
    if (_disposed || phase != WordPhase.revealing) return;
    final guess = guesses.last;
    if (guess == target) {
      _finishTurn(solved: true, timedOut: false);
    } else if (guesses.length >= maxTries) {
      _finishTurn(solved: false, timedOut: false);
    } else {
      _setPhase(WordPhase.playing);
    }
  }

  void _finishTurn({required bool solved, required bool timedOut}) {
    _revealTimer?.cancel();
    final points = solved ? (maxTries - guesses.length + 1) * 10 : 0;
    scores[playerIdx] += points;
    if (solved) wordsSolvedThisRun++;
    final result = TurnResult(
      playerIdx: playerIdx,
      word: target,
      solved: solved,
      timedOut: timedOut,
      guessesUsed: guesses.length,
      points: points,
      scoreAfter: scores[playerIdx],
    );
    history.add(result);
    _setPhase(WordPhase.roundSettled);
    onTurnSettled?.call(result);
  }

  /// Forfeits the current turn when the clock runs out.
  void forfeitTurn() {
    if (_disposed || phase != WordPhase.playing || paused) return;
    _finishTurn(solved: false, timedOut: true);
  }

  /// Acknowledged the round-settled card: advance to the next turn, or end
  /// the game when every turn is done.
  void nextTurn() {
    if (_disposed || phase != WordPhase.roundSettled) return;
    if (isVersus) {
      playerIdx++;
      if (playerIdx >= playerNames.length) {
        playerIdx = 0;
        round++;
      }
      if (round > roundsPerPlayer) {
        _setPhase(WordPhase.gameOver);
        return;
      }
    } else if (mode == PlayMode.daily) {
      _setPhase(WordPhase.gameOver);
      return;
    }
    _beginTurn();
  }

  /// Deals a fresh word for the current turn (pause-menu restart). The
  /// abandoned turn counts as neither solved nor failed.
  void restartTurn() {
    if (_disposed) return;
    if (phase == WordPhase.playing || phase == WordPhase.roundSettled) {
      _revealTimer?.cancel();
      _beginTurn();
    }
  }

  void setPaused(bool v) {
    if (_disposed || paused == v) return;
    if (v) {
      _pauseStart = DateTime.now();
    } else if (_pauseStart != null) {
      // Reveal deadlines don't burn while paused.
      final frozen = DateTime.now().difference(_pauseStart!);
      _revealDeadline = _revealDeadline.add(frozen);
      _pauseStart = null;
    }
    paused = v;
    _notify();
  }

  // -------------------------------------------------------------- timers
  void _clockTick(Timer t) {
    if (_disposed) return;
    if (paused) return;
    if (phase == WordPhase.playing) {
      secondsLeft--;
      if (secondsLeft <= 0) {
        secondsLeft = 0;
        _finishTurn(solved: false, timedOut: true);
      } else {
        _notify();
      }
    }
  }

  /// Watchdog: recovers any phase found without a live timer so the game
  /// can never freeze after a guess, a timeout, or an interruption.
  void _watchdogTick(Timer t) {
    if (_disposed) return;
    if (paused) return;
    final now = DateTime.now();
    if (phase == WordPhase.revealing && now.isAfter(_revealDeadline)) {
      // Reveal pipeline died mid-flight: apply any missing marks and settle.
      _revealTimer?.cancel();
      final row = guesses.length - 1;
      if (row >= 0 && _fb.length == wordLen) {
        for (var c = 0; c < wordLen; c++) {
          if (marks[row][c] == Mark.none) {
            marks[row][c] = _fb[c];
            _absorbKey(guesses[row][c], _fb[c]);
          }
        }
      }
      _settleReveal();
      return;
    }
    if (phase == WordPhase.playing && secondsLeft <= 0) {
      _finishTurn(solved: false, timedOut: true);
      return;
    }
    if (phase == WordPhase.idle && _started) {
      // Safety net: a turn should always be live after start().
      _beginTurn();
    }
  }

  // -------------------------------------------------------------- rules
  /// Two-pass Wordle marking: greens first, then ambers with counts.
  List<Mark> _feedback(String guess, String target) {
    final res = List.filled(wordLen, Mark.absent);
    final counts = <String, int>{};
    for (final c in target.split('')) {
      counts[c] = (counts[c] ?? 0) + 1;
    }
    for (var i = 0; i < wordLen; i++) {
      if (guess[i] == target[i]) {
        res[i] = Mark.correct;
        counts[guess[i]] = counts[guess[i]]! - 1;
      }
    }
    for (var i = 0; i < wordLen; i++) {
      if (res[i] == Mark.correct) continue;
      if ((counts[guess[i]] ?? 0) > 0) {
        res[i] = Mark.present;
        counts[guess[i]] = counts[guess[i]]! - 1;
      }
    }
    return res;
  }

  void _absorbKey(String letter, Mark mark) {
    const rank = {Mark.none: 0, Mark.absent: 1, Mark.present: 2, Mark.correct: 3};
    final cur = keyMarks[letter] ?? Mark.none;
    if (rank[mark]! > rank[cur]!) {
      keyMarks[letter] = mark;
    }
  }

  void _setPhase(WordPhase p) {
    phase = p;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revealTimer?.cancel();
    _clockTimer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }
}
