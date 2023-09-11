import 'package:flutter/material.dart';

class EllipsisText extends Text {
  const EllipsisText.rich(super.textSpan, {super.key});

  const EllipsisText(String text, {super.key})
      : super(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
}
