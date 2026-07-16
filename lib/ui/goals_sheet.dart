import 'package:flutter/material.dart';

import '../state/app_controller.dart';

/// Free-text editor for the user's life goals — what the Guide measures usage
/// against.
class GoalsSheet extends StatefulWidget {
  const GoalsSheet({super.key, required this.controller});

  final AppController controller;

  static Future<void> show(BuildContext context, AppController c) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GoalsSheet(controller: c),
    );
  }

  @override
  State<GoalsSheet> createState() => _GoalsSheetState();
}

class _GoalsSheetState extends State<GoalsSheet> {
  late final TextEditingController _text =
      TextEditingController(text: widget.controller.goals);

  @override
  void dispose() {
    _text.dispose();
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
          Text('What are you working toward?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Write it in your own words. Your guide uses this to judge when your '
            'time is drifting from what matters.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            maxLines: 6,
            minLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText:
                  'e.g. Get fit and run a 10k, ship my side project, read 20 '
                  'minutes a day, be more present with family.',
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () async {
                await widget.controller.saveGoals(_text.text);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save goals'),
            ),
          ),
        ],
      ),
    );
  }
}
