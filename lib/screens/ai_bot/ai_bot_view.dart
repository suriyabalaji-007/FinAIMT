import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/providers/chat_provider.dart';

class AIBotView extends ConsumerStatefulWidget {
  const AIBotView({super.key});

  @override
  ConsumerState<AIBotView> createState() => _AIBotViewState();
}

class _AIBotViewState extends ConsumerState<AIBotView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    '📊 Analyze my spending',
    '💰 How to save more?',
    '📉 Should I prepay loans?',
    '📈 Investment advice',
    '🧾 Tax saving tips',
    '🏦 Compare my accounts',
  ];

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Configure Gemini API Key', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Get your free API key from Google AI Studio.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: keyCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                hintStyle: const TextStyle(color: Colors.white30),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textHint))),
          ElevatedButton(
            onPressed: () {
              ref.read(geminiApiKeyProvider.notifier).setKey(keyCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ API Key updated!'), backgroundColor: AppColors.primary),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(chatLoadingProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 55, 20, 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.15), AppColors.background],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FinBot AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isLoading ? 'Analyzing your data...' : 'Powered by Gemini • Online',
                          style: TextStyle(color: isLoading ? Colors.orangeAccent : AppColors.primary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showApiKeyDialog, 
                icon: const Icon(Icons.settings_outlined, color: AppColors.textHint),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('FinBot sees your real-time balances, loans, investments & expenses to give personalized advice.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }, 
                icon: const Icon(Icons.info_outline, color: AppColors.textHint),
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
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        const SizedBox(width: 12),
                        const Text('FinBot is thinking...', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
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
                    color: isUser ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser 
                      ? Border.all(color: AppColors.primary.withOpacity(0.3))
                      : Border.all(color: Colors.white.withOpacity(0.05)),
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
                              Icon(Icons.auto_awesome, color: AppColors.primary, size: 14),
                              const SizedBox(width: 4),
                              const Text('FinBot', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      SelectableText(
                        msg['text'] as String,
                        style: TextStyle(
                          color: isUser ? Colors.white : AppColors.textPrimary, 
                          height: 1.5,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(msg['time'] as String, style: const TextStyle(color: AppColors.textHint, fontSize: 9)),
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
                    label: Text(_suggestions[index], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _send(_suggestions[index]),
                  ),
                );
              },
            ),
          ),

        // Input Area
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _send,
                    enabled: !isLoading,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: isLoading ? 'FinBot is thinking...' : 'Ask about savings, EMI, tax...',
                      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: isLoading ? null : () => _send(_controller.text),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.white10 : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: isLoading ? AppColors.textHint : Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
