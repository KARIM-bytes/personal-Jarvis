import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../state/conversation_controller.dart';
import '../theme/app_theme.dart';
import 'widgets/jarvis_orb.dart';

/// The full-screen, colorful Jarvis conversation. Jarvis speaks; the user types.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.seed,
    this.speakOpener = true,
  });

  final ConversationSeed seed;

  /// Whether to speak the opener on open. False when the overlay already spoke
  /// it (a breach), true for on-demand previews.
  final bool speakOpener;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final ConversationController _c =
      ConversationController(seed: widget.seed);
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChange);
    if (widget.speakOpener) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _c.start());
    }
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    _c.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    _input.clear();
    await _c.sendUserMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF10233A), Color(0xFF0B0E12), Color(0xFF190B2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(child: _messageList()),
              if (_c.thinking) _typingIndicator(),
              _inputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          JarvisOrb(speaking: _c.speaking, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('JARVIS',
                    style: TextStyle(
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                Text(
                  _c.speaking
                      ? 'Speaking…'
                      : _c.thinking
                          ? 'Thinking…'
                          : 'Your guide',
                  style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              await _c.silence();
              if (mounted) Navigator.of(context).maybePop();
            },
          ),
        ],
      ),
    );
  }

  Widget _messageList() {
    final messages = _c.messages;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: messages.length,
      itemBuilder: (context, i) => _bubble(messages[i]),
    );
  }

  Widget _bubble(ChatMessage m) {
    final jarvis = m.fromJarvis;
    return Align(
      alignment: jarvis ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: jarvis
              ? const LinearGradient(
                  colors: [Color(0xFF2EC5FF), Color(0xFF7A5CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: jarvis ? null : AppTheme.surfaceRaised,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(jarvis ? 4 : 18),
            bottomRight: Radius.circular(jarvis ? 18 : 4),
          ),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            color: jarvis ? Colors.black.withValues(alpha: 0.9) : Colors.white,
            height: 1.35,
            fontWeight: jarvis ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    return const Padding(
      padding: EdgeInsets.only(left: 24, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('Jarvis is thinking…',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Reply to Jarvis…',
                filled: true,
                fillColor: Colors.white10,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2EC5FF), Color(0xFF7A5CFF)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.black),
              onPressed: _c.thinking ? null : _send,
            ),
          ),
        ],
      ),
    );
  }
}
