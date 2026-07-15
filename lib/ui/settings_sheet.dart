import 'package:flutter/material.dart';

import '../state/app_controller.dart';

/// Optional LLM API key. Without it, the Guide uses built-in messages.
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, required this.controller});

  final AppController controller;

  static Future<void> show(BuildContext context, AppController c) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SettingsSheet(controller: c),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final TextEditingController _keyController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            widget.controller.hasApiKey
                ? 'An LLM key is saved. Your guide writes fresh, personal messages.'
                : 'No LLM key. Your guide uses built-in messages.',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _keyController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Anthropic API key (optional)',
              hintText: 'sk-ant-...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stored only on this device. For a personal build; a production app '
            'should proxy the key through a backend.',
            style: TextStyle(color: Colors.white38, fontSize: 11.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  await widget.controller.setApiKey('');
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Clear key'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await widget.controller.setApiKey(_keyController.text);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
