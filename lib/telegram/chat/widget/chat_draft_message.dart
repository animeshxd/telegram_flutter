import 'package:flutter/material.dart';
import 'package:tdffi/td.dart' as t;

class ChatDraftMessage extends StatelessWidget {
  const ChatDraftMessage({super.key, required this.draftMessage});
  final t.DraftMessage draftMessage;
  @override
  Widget build(BuildContext context) {
    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Draft: ',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextSpan(
            text: draftMessage.input_message_text.inputMessageText?.text.text,
            style: Theme.of(context).textTheme.bodySmall,
          )
        ],
      ),
    );
  }
}
