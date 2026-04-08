import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/services/gemini_service.dart';
import 'package:fin_aimt/core/services/voice_service.dart';

// Chat loading state
final chatLoadingProvider = NotifierProvider<ChatLoadingNotifier, bool>(ChatLoadingNotifier.new);

// Voice listening state
final isListeningProvider = NotifierProvider<IsListeningNotifier, bool>(IsListeningNotifier.new);
final voiceEnabledProvider = NotifierProvider<VoiceEnabledNotifier, bool>(VoiceEnabledNotifier.new);

class IsListeningNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  @override
  set state(bool val) => super.state = val;
}

class VoiceEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  @override
  set state(bool val) => super.state = val;
}

// API Key state
final geminiApiKeyProvider = NotifierProvider<ApiKeyNotifier, String>(ApiKeyNotifier.new);

class ApiKeyNotifier extends Notifier<String> {
  @override
  String build() => '';
  
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
              'Vanakkam! 🙏 I am FinBot, your AI financial advisor.\n\nI can now help you via **Text Chat** 💬 or **Voice Interaction** 🎙️.\n\nTry asking me about:\n• "Analyze my portfolio 📈"\n• "Should I buy more Gold? 💰"\n• "Reduce my EMI burden 🏦"',
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
      
      // AI Voice Output (TTS)
      if (ref.read(voiceEnabledProvider)) {
        ref.read(voiceServiceProvider).speak(response);
      }
    } catch (e) {
      state = [...state, {'isUser': false, 'text': '⚠️ Something went wrong. Please try again.', 'time': timeStr}];
    } finally {
      ref.read(chatLoadingProvider.notifier).setLoading(false);
    }
  }

  void startVoiceInput() {
    final voice = ref.read(voiceServiceProvider);
    ref.read(isListeningProvider.notifier).state = true;
    voice.startListening((text) {
      ref.read(isListeningProvider.notifier).state = false;
      sendMessage(text);
    });
  }

  void stopVoiceInput() {
    ref.read(voiceServiceProvider).stopListening();
    ref.read(isListeningProvider.notifier).state = false;
  }
}
