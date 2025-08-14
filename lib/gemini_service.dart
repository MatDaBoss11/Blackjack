import 'package:flutter/foundation.dart';

class GeminiService {
  static final bool _isWebPlatform = kIsWeb;
  
  static Future<void> initialize() async {
    // Disable AI features on web to avoid CORS and security issues
    if (_isWebPlatform) {
      return;
    }
    
    // For mobile platforms, you could implement proper API key handling here
    // For now, we'll skip AI initialization to ensure web deployment works
    return;
  }
  
  static Future<String> getAdvice({
    required String playerMove,
    required String correctMove,
    required List<String> playerCards,
    required String dealerUpCard,
    required int playerTotal,
    required bool isPlayerSoft,
    required bool isPair,
    required bool canDouble,
    required bool canSplit,
  }) async {
    // Return basic feedback for web platform (AI disabled for security/CORS)
    if (_isWebPlatform) {
      return _getBasicFeedback(playerMove, correctMove, playerTotal, isPlayerSoft, isPair);
    }
    
    // For mobile platforms, AI could work with proper backend setup
    return 'The correct move was ${_getMoveDescription(correctMove)}. Keep practicing!';
  }
  
  static String _getBasicFeedback(String playerMove, String correctMove, int playerTotal, bool isPlayerSoft, bool isPair) {
    final playerDesc = _getMoveDescription(playerMove);
    final correctDesc = _getMoveDescription(correctMove);
    
    if (correctMove == 'D') {
      return 'Double down gives you the best mathematical advantage here. $correctDesc was the optimal play instead of $playerDesc.';
    } else if (correctMove == 'P') {
      return 'Splitting this pair gives you better odds. $correctDesc was the optimal play instead of $playerDesc.';
    } else if (correctMove == 'S' && playerTotal >= 17) {
      return 'Standing on $playerTotal is safer - avoid busting! $correctDesc was the optimal play instead of $playerDesc.';
    } else if (correctMove == 'H' && playerTotal <= 11) {
      return 'Hitting with $playerTotal gives you great odds to improve. $correctDesc was the optimal play instead of $playerDesc.';
    } else {
      return 'The mathematically correct play was $correctDesc instead of $playerDesc. Keep studying basic strategy!';
    }
  }
  
  static String _getMoveDescription(String move) {
    switch (move) {
      case 'H': return 'Hit';
      case 'S': return 'Stand';
      case 'D': return 'Double';
      case 'P': return 'Split';
      default: return move;
    }
  }
}