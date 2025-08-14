import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const BlackjackApp());

class BlackjackApp extends StatelessWidget {
  const BlackjackApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blackjack Trainer',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const TrainerScreen(),
    );
  }
}

// ---------- Models ----------
class CardModel {
  final String rank; // A,2..10,J,Q,K
  final String suit; // ♠ ♥ ♦ ♣
  CardModel(this.rank, this.suit);
  int get value {
    if (rank == 'A') return 11;
    if (['J', 'Q', 'K'].contains(rank)) return 10;
    return int.parse(rank);
  }
  String get pretty => "$rank$suit";
}

class Deck {
  final int decks;
  final Random _rng = Random();
  final List<CardModel> _cards = [];
  Deck({this.decks = 2}) { _build(); }
  void _build() {
    _cards.clear();
    const ranks = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
    const suits = ['♠','♥','♦','♣'];
    for (int d = 0; d < decks; d++) {
      for (final r in ranks) {
        for (final s in suits) {
          _cards.add(CardModel(r, s));
        }
      }
    }
    _shuffle();
  }
  void _shuffle() {
    for (int i = _cards.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final tmp = _cards[i];
      _cards[i] = _cards[j];
      _cards[j] = tmp;
    }
  }
  CardModel draw() {
    if (_cards.isEmpty) _build();
    if (_cards.length < decks * 52 * 0.25) _build();
    return _cards.removeLast();
  }
}

class Hand {
  final List<CardModel> cards = [];
  bool get isPair => cards.length == 2 && _rankKey(cards[0].rank) == _rankKey(cards[1].rank);
  bool get isBlackjack => cards.length == 2 && total == 21;
  int get total {
    int sum = 0; int aces = 0;
    for (final c in cards) {
      if (c.rank == 'A') aces++; else sum += c.value;
    }
    sum += aces * 11;
    while (sum > 21 && aces > 0) { sum -= 10; aces--; }
    return sum;
  }
  bool get isSoft {
    int sum = 0; int aces = 0;
    for (final c in cards) { if (c.rank == 'A') aces++; else sum += c.value; }
    sum += aces * 11;
    int softAces = aces;
    while (sum > 21 && softAces > 0) { sum -= 10; softAces--; }
    return softAces > 0;
  }
  bool get isBust => total > 21;
}

String _rankKey(String r){
  if (r == 'J' || r == 'Q' || r == 'K') return '10';
  return r;
}
String upcardKey(CardModel c){
  return _rankKey(c.rank) == 'A' ? 'A' : _rankKey(c.rank);
}

// ---------- Strategy (S17, no surrender, DAS off) ----------
/// Returns one of: H,S,D,Ds,P
String recommendMove({required Hand hand, required CardModel dealerUp, required bool canDouble, required bool canSplit}){
  final up = upcardKey(dealerUp);
  final upVal = up == 'A' ? 11 : int.parse(up);
  final total = hand.total;
  final soft = hand.isSoft;

  // Pairs first
  if (canSplit && hand.isPair){
    final pr = _rankKey(hand.cards.first.rank);
    switch(pr){
      case 'A': return 'P';
      case '10': return 'S';
      case '9': return ([2,3,4,5,6,8,9].contains(upVal)) ? 'P' : 'S';
      case '8': return 'P';
      case '7': return ([2,3,4,5,6,7].contains(upVal)) ? 'P' : 'H';
      case '6': return ([3,4,5,6].contains(upVal)) ? 'P' : 'H';
      case '5': return 'D';
      case '4': return ([5,6].contains(upVal)) ? 'P' : 'H';
      case '3':
      case '2': return ([4,5,6,7].contains(upVal)) ? 'P' : 'H';
    }
  }

  // Soft totals
  if (soft && hand.cards.length >= 2){
    final other = total - 11; // A + other
    switch(other){
      case 9: return 'S'; // A,9
      case 8: return upVal == 6 ? (canDouble ? 'D' : 'S') : 'S';
      case 7:
        if ([3,4,5,6].contains(upVal)) return canDouble ? 'D' : 'S';
        if ([2,7,8].contains(upVal)) return 'S';
        return 'H';
      case 6: return ([3,4,5,6].contains(upVal)) ? (canDouble ? 'D' : 'H') : 'H';
      case 5:
      case 4: return ([4,5,6].contains(upVal)) ? (canDouble ? 'D' : 'H') : 'H';
      case 3:
      case 2: return ([5,6].contains(upVal)) ? (canDouble ? 'D' : 'H') : 'H';
    }
  }

  // Hard totals
  if (total >= 17) return 'S';
  if (total == 16) return ([2,3,4,5,6].contains(upVal)) ? 'S' : 'H';
  if (total == 15) return ([2,3,4,5,6].contains(upVal)) ? 'S' : 'H';
  if (total == 14 || total == 13) return ([2,3,4,5,6].contains(upVal)) ? 'S' : 'H';
  if (total == 12) return ([4,5,6].contains(upVal)) ? 'S' : 'H';
  if (total == 11) return (upVal == 11) ? 'H' : (canDouble ? 'D' : 'H');
  if (total == 10) return ([2,3,4,5,6,7,8,9].contains(upVal)) ? (canDouble ? 'D' : 'H') : 'H';
  if (total == 9)  return ([3,4,5,6].contains(upVal)) ? (canDouble ? 'D' : 'H') : 'H';
  return 'H';
}

class TrainerScreen extends StatefulWidget {
  const TrainerScreen({super.key});
  @override
  State<TrainerScreen> createState() => _TrainerScreenState();
}

enum Phase { betting, playerTurn, dealerTurn, roundOver }

class _TrainerScreenState extends State<TrainerScreen> {
  final Deck shoe = Deck(decks: 2); // forced to 2 per your spec
  final Hand player = Hand();
  final Hand dealer = Hand();
  Phase phase = Phase.betting;
  bool hideHole = true;
  bool doubled = false;
  bool justSplitAces = false;
  List<Hand> splitHands = []; // queue of remaining player hands when splitting
  int currentHandIndex = 0;

  // stats
  int hands = 0, correct = 0, wins = 0, losses = 0, pushes = 0;

  // feedback
  String feedback = '';
  Color feedbackColor = Colors.transparent;

  void _resetHands(){
    player.cards.clear();
    dealer.cards.clear();
    hideHole = true;
    doubled = false;
    justSplitAces = false;
    splitHands.clear();
    currentHandIndex = 0;
    feedback = '';
  }

  void newShoe(){
    setState((){
      _resetHands();
      phase = Phase.betting;
    });
  }

  void deal(){
    setState((){
      _resetHands();
      player.cards.add(shoe.draw());
      dealer.cards.add(shoe.draw());
      player.cards.add(shoe.draw());
      dealer.cards.add(shoe.draw());
      phase = Phase.playerTurn;
      if (player.isBlackjack || dealer.isBlackjack){
        _revealAndSettle();
      }
    });
  }

  void _revealAndSettle(){
    hideHole = false;
    _dealerPlayS17();
    _settleAll();
  }

  void _dealerPlayS17(){
    // Dealer stands on all 17 including soft 17
    while(dealer.total < 17 || (dealer.total == 17 && dealer.isSoft == false ? false : false)){
      // break at 17 regardless of soft/hard
      if (dealer.total >= 17) break;
      dealer.cards.add(shoe.draw());
    }
  }

  void _settleAll(){
    // handle single or split sequence
    List<Hand> handsToScore = [player, ...splitHands];
    for (final h in handsToScore){
      if (h.isBust) losses++;
      else if (dealer.isBust) wins++;
      else if (h.total > dealer.total) wins++;
      else if (h.total < dealer.total) losses++;
      else pushes++;
    }
    hands += handsToScore.length;
    phase = Phase.roundOver;
    setState((){});
  }

  void _showFeedback(bool wasCorrect, String shouldLabel){
    setState((){
      feedback = wasCorrect ? 'Correct move!' : 'Incorrect. Correct play: $shouldLabel';
      feedbackColor = wasCorrect ? Colors.green : Colors.red;
      if (wasCorrect) correct++;
    });
  }

  Hand get activeHand => currentHandIndex == 0 ? player : splitHands[currentHandIndex - 1];

  bool get canDouble => phase == Phase.playerTurn && activeHand.cards.length == 2 && !doubled;
  bool get canSplit => phase == Phase.playerTurn && activeHand.isPair && !doubled;

  void _nextHandOrDealer(){
    if (currentHandIndex < splitHands.length){
      currentHandIndex++;
      // If we just moved onto a hand created by splitting aces, auto-stand because one card only rule
      if (justSplitAces && activeHand.cards.length == 1){
        activeHand.cards.add(shoe.draw());
        _finalizePlayerHand();
      }
      setState((){});
    } else {
      hideHole = false;
      _dealerPlayS17();
      _settleAll();
    }
  }

  void _finalizePlayerHand(){
    if (activeHand.isBust){
      _nextHandOrDealer();
      return;
    }
    // standing or after double
    _nextHandOrDealer();
  }

  void playerMove(String move){
    if (phase != Phase.playerTurn) return;
    final code = recommendMove(hand: activeHand, dealerUp: dealer.cards.first, canDouble: canDouble, canSplit: canSplit);
    final should = _toLabel(code, canDouble);
    final normalized = _normalize(move, canDouble);
    final normalizedShould = _normalize(should.code, canDouble);
    final isRight = normalized == normalizedShould;
    _showFeedback(isRight, should.label);

    switch(move){
      case 'H':
        activeHand.cards.add(shoe.draw());
        if (activeHand.isBust){ _finalizePlayerHand(); } else { setState((){}); }
        break;
      case 'S':
        _finalizePlayerHand();
        break;
      case 'D':
        if (!canDouble){
          // fallback acts as hit
          activeHand.cards.add(shoe.draw());
          _finalizePlayerHand();
        } else {
          doubled = true; // per-hand flag only matters for current hand
          activeHand.cards.add(shoe.draw());
          _finalizePlayerHand();
          doubled = false;
        }
        break;
      case 'P':
        if (!canSplit){ setState((){}); break; }
        // split into two hands
        final left = Hand();
        final right = Hand();
        left.cards.add(activeHand.cards[0]);
        right.cards.add(activeHand.cards[1]);
        // replace current hand with left, push right to queue
        activeHand.cards
          ..clear()
          ..addAll(left.cards);
        splitHands.insert(currentHandIndex, right);
        // Draw one card to each hand
        activeHand.cards.add(shoe.draw());
        right.cards.add(shoe.draw());
        // Split Aces rule: one card only
        justSplitAces = _rankKey(activeHand.cards.first.rank) == 'A';
        if (justSplitAces){
          // auto-stand both hands after receiving one card each
          _finalizePlayerHand();
        } else {
          setState((){});
        }
        break;
    }
  }

  ({String code, String label}) _toLabel(String code, bool canDouble){
    if (code == 'Ds') return canDouble ? (code: 'D', label: 'Double') : (code: 'S', label: 'Stand');
    if (code == 'D')  return canDouble ? (code: 'D', label: 'Double') : (code: 'H', label: 'Hit');
    if (code == 'P')  return (code: 'P', label: 'Split');
    if (code == 'S')  return (code: 'S', label: 'Stand');
    return (code: 'H', label: 'Hit');
  }

  String _normalize(String code, bool canDouble){
    if (code == 'Ds') return canDouble ? 'D' : 'S';
    return code;
  }

  Color _suitColor(String suit){
    return (suit == '♥' || suit == '♦') ? Colors.red.shade700 : Colors.black87;
  }

  Widget _playingCard(CardModel c, {bool faceDown = false, double scale = 1.0}){
    final double width = 64 * scale; // aspect ~0.7
    final double height = 90 * scale;
    if (faceDown){
      return Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.rank, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _suitColor(c.suit))),
                Text(c.suit, style: TextStyle(fontSize: 18, height: 1.05, color: _suitColor(c.suit))),
              ],
            ),
          ),
          Positioned(
            right: 8,
            bottom: 6,
            child: Transform.rotate(
              angle: 3.1416,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.rank, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _suitColor(c.suit))),
                  Text(c.suit, style: TextStyle(fontSize: 18, height: 1.05, color: _suitColor(c.suit))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle get _actionStyle => FilledButton.styleFrom(
    backgroundColor: Colors.green.shade600,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    shape: const StadiumBorder(),
  );

  Widget _doubleChipButton({required VoidCallback? onPressed, required bool enabled}){
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.black54,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(18),
        elevation: 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Double', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('x2'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = activeHand;
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.7),
              radius: 1.2,
              colors: [
                Colors.green.shade700,
                Colors.green.shade900,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Top-right controls
              Positioned(
                right: 12,
                top: 8,
                child: Row(
                  children: [
                    FilledButton.tonal(onPressed: newShoe, child: const Text('New Shoe')),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: phase==Phase.betting?deal:null, child: const Text('Deal')),
                  ],
                ),
              ),

              // Dealer area (top center)
              Align(
                alignment: const Alignment(0, -0.75),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Dealer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: dealer.cards.asMap().entries.map((e){
                        final idx = e.key; final c = e.value;
                        final faceDown = idx==1 && hideHole;
                        return _playingCard(c, faceDown: faceDown, scale: 1.1);
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(20)),
                      child: Text('Total: ' + (hideHole? '?': dealer.total.toString()), style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),

              // Actions area (center)
              Align(
                alignment: const Alignment(0, -0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 140,
                      child: FilledButton(
                        onPressed: phase==Phase.playerTurn?()=>playerMove('H'):null,
                        style: _actionStyle,
                        child: const Text('Hit'),
                      ),
                    ),
                    _doubleChipButton(
                      onPressed: ()=>playerMove('D'),
                      enabled: phase==Phase.playerTurn && canDouble,
                    ),
                    SizedBox(
                      width: 140,
                      child: FilledButton(
                        onPressed: phase==Phase.playerTurn?()=>playerMove('S'):null,
                        style: _actionStyle,
                        child: const Text('Stand'),
                      ),
                    ),
                  ],
                ),
              ),

              // Optional Split chip under the center if available
              if (phase==Phase.playerTurn)
                Align(
                  alignment: const Alignment(0, 0.18),
                  child: ElevatedButton(
                    onPressed: canSplit ? ()=>playerMove('P') : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade700,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Split' + (canSplit? '': ' (N/A)')),
                  ),
                ),

              // Player area (bottom center)
              Align(
                alignment: const Alignment(0, 0.65),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Player' + (splitHands.isEmpty? '' : ' (Hand ${currentHandIndex+1}/${splitHands.length+1})'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: active.cards.map((c)=>_playingCard(c, scale: 1.2)).toList(),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(20)),
                      child: Text('Total: ${active.total}' + (active.isSoft? ' (soft)': ''), style: const TextStyle(color: Colors.white)),
                    ),
                    if (feedback.isNotEmpty) Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(feedback, style: TextStyle(color: feedbackColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Stats (bottom-left)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    'Hands: $hands  Correct: $correct  Win: $wins  Loss: $losses  Push: $pushes',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),

              if (phase==Phase.roundOver)
                Align(
                  alignment: const Alignment(0, 0.92),
                  child: FilledButton(
                    onPressed: ()=>deal(),
                    style: _actionStyle,
                    child: const Text('Next Hand'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
