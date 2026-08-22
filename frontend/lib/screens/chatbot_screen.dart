import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';
import '../widgets/chat_bubble.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _apiService = ApiService();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'sender': 'bot',
      'message':
          '👋 Hi! I\'m your HostelSwap assistant.\n\n'
          'You can:\n'
          '• Post a swap request: "I have BH-2 Non-AC 3-seater, want BH-1 AC 2-seater"\n'
          '• Ask about policies: "What is the deadline for hostel shift?"\n'
          '• Get help: "How do I withdraw my request?"',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chatbot Assistant'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(
                  message: message['message']!,
                  isUser: message['sender'] == 'user',
                );
              },
            ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add({'sender': 'user', 'message': message});
      _messageController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    // Get user ID
    final user = ref.read(authProvider);
    if (user == null) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'message': '⚠️ Please login first to use the chatbot.',
        });
        _isLoading = false;
      });
      return;
    }

    try {
      // Send to FastAPI
      final response = await _apiService.sendChatMessage(message, user.collegeId);

      // Check if it's a swap request
      if (response['intent'] == 'swap_request' && response['parsed_data'] != null) {
        // Save the request to Supabase
        final data = response['parsed_data'];
        final requestData = {
          'user_id': user.collegeId,
          'current_hostel': data['current_hostel'],
          'current_ac': data['current_ac'],
          'current_seater': data['current_seater'],
          'desired_hostel': data['desired_hostel'],
          'desired_ac': data['desired_ac'],
          'desired_seater': data['desired_seater'],
          'status': 'active',
        };
        
        await ref.read(createRequestProvider(requestData).future);
        
        setState(() {
          _messages.add({
            'sender': 'bot',
            'message': '✅ ${response['message']}\n\n'
                '📋 Your request has been posted! Check the dashboard to see it.',
          });
        });
        
        // Refresh dashboard
        ref.invalidate(requestProvider);
      } else {
        // Regular response or RAG answer
        setState(() {
          _messages.add({
            'sender': 'bot',
            'message': response['message'] ?? response['answer'] ?? 'I didn\'t understand that.',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'message': '❌ Error: $e\n\nPlease try again or use the manual form.',
        });
      });
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _clearChat() {
    setState(() {
      _messages = [
        {
          'sender': 'bot',
          'message': '👋 Chat cleared! How can I help you?',
        },
      ];
    });
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}