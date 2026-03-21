import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/services/gemini_service.dart';

// Chat loading state
final chatLoadingProvider = NotifierProvider<ChatLoadingNotifier, bool>(ChatLoadingNotifier.new);

// API Key state
final geminiApiKeyProvider = NotifierProvider<ApiKeyNotifier, String>(ApiKeyNotifier.new);

class ApiKeyNotifier extends Notifier<String> {
  @override
  String build() => 'AIzaSyDttAPd9KeOAP1GjY-aETAzYfPJhFMPM3M';
  
  void setKey(String key) => state = key;
}

class ChatLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setLoading(bool val) => state = val;
}

// Chat Notifier using Gemini AI
final chatMessagesProvider =
    NotifierProvider<ChatNotifier, List<Map<String, dynamic>>>(
        ChatNotifier.new);

class ChatNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [
        {
          'isUser': false,
          'text':
              'Namaste! 🙏 I am FinBot, your AI financial advisor powered by Gemini. I can see your live financial data and give personalized advice.\n\nTry asking:\n• "How can I reduce my EMI burden?"\n• "Should I invest more in gold?"\n• "Analyze my spending"',
          'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'
        }
      ];

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final timeStr = '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    // Add user message
    state = [...state, {'isUser': true, 'text': text, 'time': timeStr}];

    // Show loading
    ref.read(chatLoadingProvider.notifier).setLoading(true);

    try {
      // Call Gemini
      final gemini = ref.read(geminiServiceProvider);
      final response = await gemini.sendMessage(text);

      final responseTime = '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
      state = [...state, {'isUser': false, 'text': response, 'time': responseTime}];
    } catch (e) {
      state = [...state, {'isUser': false, 'text': '⚠️ Something went wrong. Please try again.', 'time': timeStr}];
    } finally {
      ref.read(chatLoadingProvider.notifier).setLoading(false);
    }
  }
}
