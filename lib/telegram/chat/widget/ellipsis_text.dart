import 'package:flutter/material.dart';

class EllipsisText extends Text {
  const EllipsisText.rich(super.textSpan, {super.key, this.removeNewLine = false, super.style});
  final bool removeNewLine;

  EllipsisText(String text, {super.key, this.removeNewLine = false, super.style})
      : super(
          removeNewLine? text : text.replaceAll('\n', ''),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
}
