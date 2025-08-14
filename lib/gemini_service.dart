import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static GenerativeModel? _model;
  
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
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
    if (_model == null) {
      await initialize();
    }
    
    final prompt = '''
You are a professional blackjack dealer and strategy expert. A player just made an incorrect move in blackjack training.

SITUATION:
- Player cards: ${playerCards.join(', ')}
- Player total: $playerTotal${isPlayerSoft ? ' (soft)' : ''}
- Dealer up card: $dealerUpCard
- Player chose: ${_getMoveDescription(playerMove)}
- Correct play: ${_getMoveDescription(correctMove)}
- Can double: $canDouble
- Can split: ${canSplit ? 'Yes (pair)' : 'No'}

Please explain in 1-2 concise sentences:
1. Why their move was wrong
2. Why the correct move is better

Be encouraging and educational. Focus on strategy reasoning, not just rules.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Try the correct move next time!';
    } catch (e) {
      return 'The correct move was ${_getMoveDescription(correctMove)}. Keep practicing!';
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