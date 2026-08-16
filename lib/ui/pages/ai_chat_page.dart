import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ai_provider.dart';
import '../../models/ai_config.dart' show AIModelProvider, AIModel, AIConversation, AIMessage, AIFile;

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AIProvider>().createConversation();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI对话'),
        actions: [
          Consumer<AIProvider>(
            builder: (context, provider, _) {
              return PopupMenuButton<AIProvider>(
                icon: const Icon(Icons.smart_toy),
                onSelected: (model) => provider.selectModel(model),
                itemBuilder: (context) {
                  return provider.internalModels.map((model) {
                    return PopupMenuItem<AIProvider>(
                      value: model,
                      child: Row(
                        children: [
                          if (provider.currentModel?.id == model.id)
                            const Icon(Icons.check, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(model.name),
                        ],
                      ),
                    );
                  }).toList();
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<AIProvider>(
              builder: (context, provider, _) {
                if (provider.currentConversation == null) {
                  return const Center(
                    child: Text('选择AI模型开始对话'),
                  );
                }

                final messages = provider.currentConversation!.messages;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '与 ${provider.currentModel?.name ?? "AI"} 对话',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      message: message,
                      isUser: message.role == 'user',
                    );
                  },
                );
              },
            ),
          ),
          Consumer<AIProvider>(
            builder: (context, provider, _) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: '输入消息...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(provider),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (provider.isGenerating)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.send),
                        color: const Color(0xFF6366F1),
                        onPressed: () => _sendMessage(provider),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage(AIProvider provider) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    provider.sendMessage(text);
    
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }
}

class _MessageBubble extends StatelessWidget {
  final AIMessage message;
  final bool isUser;

  const _MessageBubble({
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF6366F1)
              : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
