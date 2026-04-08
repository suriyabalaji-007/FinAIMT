import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/chat_provider.dart';
import 'package:fin_aimt/core/services/voice_service.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';

class AIBotView extends ConsumerStatefulWidget {
  const AIBotView({super.key});

  @override
  ConsumerState<AIBotView> createState() => _AIBotViewState();
}

class _AIBotViewState extends ConsumerState<AIBotView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    '📈 Is this a good time to buy Stocks?',
    '📊 Analyze my investment portfolio',
    '🏦 How to open a Post Office FD?',
    '📉 Should I prepay my high-interest loans?',
    '💰 Best Mutual Funds for 12% returns?',
    '🛡️ How is my data kept private?',
  ];

  @override
  void initState() {
    super.initState();
    ref.read(voiceServiceProvider).init();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    ref.read(chatMessagesProvider.notifier).sendMessage(text);
    _controller.clear();
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 500), _scrollToBottom);
  }

  void _showApiKeyDialog() {
    final keyCtrl = TextEditingController(text: ref.read(geminiApiKeyProvider));
    final voiceEnabled = ref.read(voiceEnabledProvider);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('FinBot Settings', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configure your preferences and API keys.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('AI Voice Output', style: TextStyle(fontSize: 14)),
              value: voiceEnabled,
              onChanged: (val) {
                ref.read(voiceEnabledProvider.notifier).state = val;
                Navigator.pop(ctx);
                _showApiKeyDialog();
              },
            ),
            const Divider(),
            const Text('Groq API Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: keyCtrl,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'gsk_...',
                hintStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12)), borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary), borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              ref.read(geminiApiKeyProvider.notifier).setKey(keyCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('✅ Settings updated!'), backgroundColor: Theme.of(context).colorScheme.primary),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(chatLoadingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Ensure solid background
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 55, 20, 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary.withOpacity(0.15), Theme.of(context).scaffoldBackgroundColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => ref.read(currentTabProvider.notifier).setTab(0),
                      icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white70 : Colors.black54, size: 20),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.7)]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FinBot AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : LightColors.textPrimary)),
                          Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isLoading ? 'Analyzing Market Trends...' : 'Secure & Encrypted • Real-time Data',
                                style: TextStyle(color: isLoading ? Colors.orangeAccent : Theme.of(context).colorScheme.primary, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showApiKeyDialog, 
                      icon: const Icon(Icons.settings_outlined, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, color: Colors.green, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'End-to-end encrypted financial analysis active',
                        style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Typing indicator
                if (index == messages.length && isLoading) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
                          const SizedBox(width: 12),
                          const Text('FinBot is thinking...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                final msg = messages[index];
                final isUser = msg['isUser'] as bool;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      border: isUser 
                        ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3))
                        : Border.all(color: (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 14),
                                const SizedBox(width: 4),
                                Text('FinBot', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        SelectableText(
                          msg['text'] as String,
                          style: TextStyle(
                            color: isUser 
                              ? (isDark ? Colors.white : LightColors.textPrimary) 
                              : (isDark ? Colors.white : LightColors.textPrimary), 
                            height: 1.5,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(msg['time'] as String, style: const TextStyle(color: Colors.grey, fontSize: 9)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Suggestion Chips
          if (messages.length <= 2)
            SizedBox(
              height: 40,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(_suggestions[index], style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : LightColors.textSecondary)),
                      backgroundColor: Theme.of(context).cardTheme.color,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () => _send(_suggestions[index]),
                    ),
                  );
                },
              ),
            ),

          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.only(bottom: 110), // Lift above the floating nav bar (80 height + 25 bottom)
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, -5))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        onSubmitted: _send,
                        enabled: !isLoading,
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : LightColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: isLoading ? 'Thinking...' : 'Type query...',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _VoiceInputButton(small: true),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: isLoading ? null : () => _send(_controller.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceInputButton extends ConsumerWidget {
  final bool small;
  const _VoiceInputButton({this.small = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isListening = ref.watch(isListeningProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onLongPress: () => ref.read(chatMessagesProvider.notifier).startVoiceInput(),
      onLongPressUp: () => ref.read(chatMessagesProvider.notifier).stopVoiceInput(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: small ? 44 : 70,
        height: small ? 44 : 70,
        decoration: BoxDecoration(
          color: isListening ? Colors.redAccent.withOpacity(0.1) : primaryColor.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: isListening ? Colors.redAccent : primaryColor.withOpacity(0.3),
            width: isListening ? (small ? 2 : 4) : 2,
          ),
          boxShadow: isListening ? [
            BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)
          ] : [],
        ),
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none_rounded,
          color: isListening ? Colors.redAccent : primaryColor,
          size: small ? 22 : 32,
        ),
      ),
    );
  }
}
