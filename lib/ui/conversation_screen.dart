import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../state/conversation_controller.dart';
import '../theme/app_theme.dart';
import 'widgets/glass.dart';
import 'widgets/jarvis_orb.dart';

/// The full-screen Jarvis conversation. Jarvis speaks; the user types.
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
  final JarvisOrbController _orb = JarvisOrbController();

  /// True briefly after each keystroke so the orb "listens" while you type.
  bool _typing = false;
  Timer? _typingDecay;

  OrbMood get _mood {
    if (_c.speaking) return OrbMood.speaking;
    if (_c.thinking) return OrbMood.thinking;
    if (_typing) return OrbMood.listening;
    return OrbMood.idle;
  }

  void _onTyped(String _) {
    _orb.pulse();
    if (!_typing) setState(() => _typing = true);
    _typingDecay?.cancel();
    _typingDecay = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _typing = false);
    });
  }

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
          duration: AppTheme.normal,
          curve: AppTheme.ease,
        );
      }
    });
  }

  @override
  void dispose() {
    _typingDecay?.cancel();
    _c.removeListener(_onChange);
    _c.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    // The orb gathers the message inward before the brain starts on it.
    _orb.absorb();
    _typingDecay?.cancel();
    setState(() => _typing = false);
    await _c.sendUserMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(child: _messageList()),
              _inputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.s2, AppTheme.s1, AppTheme.s1, AppTheme.s1),
      child: Row(
        children: [
          JarvisOrb(mood: _mood, controller: _orb, size: 56),
          const SizedBox(width: AppTheme.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('JARVIS',
                    style: TextStyle(
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: AppTheme.fast,
                  child: Text(
                    switch (_mood) {
                      OrbMood.speaking => 'Speaking…',
                      OrbMood.thinking => 'Thinking…',
                      OrbMood.listening => 'Listening…',
                      OrbMood.idle => 'Your guide',
                    },
                    key: ValueKey(_mood),
                    style: const TextStyle(
                        color: AppTheme.textTertiary, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppTheme.textTertiary),
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
    final showTyping = _c.thinking;
    return ListView.builder(
      controller: _scroll,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppTheme.s2, AppTheme.s1, AppTheme.s2, AppTheme.s1),
      itemCount: messages.length + (showTyping ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == messages.length) return _thinkingBubble();
        return _bubble(messages[i]);
      },
    );
  }

  Widget _bubble(ChatMessage m) {
    final jarvis = m.fromJarvis;
    return Entrance(
      child: Align(
        alignment: jarvis ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.s2, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            gradient: jarvis ? null : AppTheme.heroGradient,
            color: jarvis ? const Color(0x0DFFFFFF) : null,
            border: jarvis
                ? Border.all(color: AppTheme.glassBorder)
                : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppTheme.rMd),
              topRight: const Radius.circular(AppTheme.rMd),
              bottomLeft: Radius.circular(jarvis ? 6 : AppTheme.rMd),
              bottomRight: Radius.circular(jarvis ? AppTheme.rMd : 6),
            ),
            boxShadow: jarvis
                ? const []
                : [
                    BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
          ),
          child: Text(
            m.text,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.42,
              fontWeight: jarvis ? FontWeight.w400 : FontWeight.w600,
              color: jarvis
                  ? AppTheme.textPrimary
                  : const Color(0xFF03121C),
            ),
          ),
        ),
      ),
    );
  }

  Widget _thinkingBubble() {
    return const Entrance(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: GlassCard(
            radius: AppTheme.rMd,
            padding:
                EdgeInsets.symmetric(horizontal: AppTheme.s2, vertical: 14),
            child: TypingDots(),
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppTheme.s2, AppTheme.s1, AppTheme.s2,
          AppTheme.s1 + MediaQuery.of(context).viewInsets.bottom),
      child: GlassCard(
        blur: true,
        radius: AppTheme.rLg,
        padding: const EdgeInsets.fromLTRB(AppTheme.s1, 6, 6, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                onChanged: _onTyped,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(fontSize: 14.5),
                decoration: const InputDecoration(
                  hintText: 'Reply to Jarvis…',
                  filled: false,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.s1),
            AnimatedOpacity(
              duration: AppTheme.fast,
              opacity: _c.thinking ? 0.4 : 1,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.3),
                        blurRadius: 14),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _c.thinking ? null : _send,
                    child: const Icon(Icons.arrow_upward_rounded,
                        color: Color(0xFF03121C), size: 21),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
