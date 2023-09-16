import 'package:flutter/material.dart';

class EllipsisText extends Text {
  const EllipsisText.rich(super.textSpan, {super.key, this.removeNewLine = false});
  final bool removeNewLine;

  EllipsisText(String text, {super.key, this.removeNewLine = false})
      : super(
          removeNewLine? text : text.replaceAll('\n', ''),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
}
