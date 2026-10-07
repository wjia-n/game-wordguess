import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const WordGuessApp());

class WordGuessApp extends StatelessWidget {
  const WordGuessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Word Guess',
      tagline: 'Six tries, one sneaky 5-letter word. Daily puzzle plus endless mode! 💬',
      emoji: '💬',
      slug: 'wordguess',
      howToPlay:
          '• Guess the hidden 5-letter word in 6 tries.\n• 🟩 Green = right letter, right spot.\n• 🟨 Amber = right letter, wrong spot.\n• ⬜ Grey = not in the word at all.\n• Round 1 is the daily word — rounds 2 & 3 are random. 3 rounds per run!',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => WordGuessScreen(players: players, callbacks: cb),
    );
  }
}
