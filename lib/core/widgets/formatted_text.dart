import 'dart:convert';
import 'package:flutter/material.dart';

class FormattedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextOverflow overflow;
  final int? maxLines;

  const FormattedText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.clip,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    // Check if the input is a JSON string
    final trimmedText = text.trim();
    if (trimmedText.startsWith('[') || trimmedText.startsWith('{')) {
      try {
        final List<InlineSpan> jsonSpans = _parseJsonDescription(trimmedText, baseStyle);
        if (jsonSpans.isNotEmpty) {
          return RichText(
            textAlign: textAlign,
            overflow: overflow,
            maxLines: maxLines,
            text: TextSpan(
              children: jsonSpans,
              style: baseStyle,
            ),
          );
        }
      } catch (_) {
        // Fall back to plain text parsing if JSON decoding fails
      }
    }

    // 1. Decode HTML entities and replace structural tags
    String processed = text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<li>', caseSensitive: false), ' • ')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<ul>|</ul>|<ol>|</ol>', caseSensitive: false), '\n')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    // Strip any HTML tag except bold/italic formatting tags: <b>, </b>, <strong>, </strong>, <i>, </i>, <em>, </em>
    final tagRegExp = RegExp(r'</?([a-zA-Z0-9]+)[^>]*>');
    processed = processed.replaceAllMapped(tagRegExp, (match) {
      final tagName = match.group(1)!.toLowerCase();
      if (tagName == 'b' || tagName == 'strong' || tagName == 'i' || tagName == 'em') {
        return match.group(0)!; // Keep formatting tags intact
      }
      return ''; // Strip all other HTML tags
    });

    // Normalize spacing and trim
    processed = processed.trim();

    // 2. State-based parsing for inline formats (bold/italic)
    final List<InlineSpan> spans = _parseInlineHtmlAndMarkdown(processed, baseStyle);

    return RichText(
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      text: TextSpan(
        children: spans,
        style: baseStyle,
      ),
    );
  }

  List<InlineSpan> _parseInlineHtmlAndMarkdown(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    bool isBold = false;
    bool isItalic = false;

    // Regexp to catch bold/italic HTML tags and markdown qualifiers
    final tokenRegex = RegExp(
      r'(<b>|</b>|<strong>|</strong>|<i>|</i>|<em>|</em>|\*\*|\*)',
      caseSensitive: false,
    );

    int lastIndex = 0;
    for (final match in tokenRegex.allMatches(text)) {
      // Add preceding plain text block
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle.copyWith(
            fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
            fontStyle: isItalic ? FontStyle.italic : baseStyle.fontStyle,
          ),
        ));
      }

      // Update state flags based on token
      final token = match.group(0)!.toLowerCase();
      if (token == '<b>' || token == '<strong>') {
        isBold = true;
      } else if (token == '</b>' || token == '</strong>') {
        isBold = false;
      } else if (token == '<i>' || token == '<em>') {
        isItalic = true;
      } else if (token == '</i>' || token == '</em>') {
        isItalic = false;
      } else if (token == '**') {
        isBold = !isBold;
      } else if (token == '*') {
        isItalic = !isItalic;
      }

      lastIndex = match.end;
    }

    // Add trailing plain text block
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle.copyWith(
          fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
          fontStyle: isItalic ? FontStyle.italic : baseStyle.fontStyle,
        ),
      ));
    }

    return spans;
  }

  List<InlineSpan> _parseJsonDescription(String jsonStr, TextStyle baseStyle) {
    final decoded = json.decode(jsonStr);

    // Format A: Quill Delta (JSON List of insert blocks)
    if (decoded is List) {
      final List<InlineSpan> spans = [];

      // If it is a simple list of strings, format as a bullet list
      if (decoded.every((e) => e is String)) {
        for (final item in decoded) {
          spans.add(TextSpan(text: '• $item\n', style: baseStyle));
        }
        return spans;
      }

      for (final item in decoded) {
        if (item is Map) {
          final insert = item['insert'];
          if (insert is String) {
            final attrs = item['attributes'] as Map?;
            bool isBold = false;
            bool isItalic = false;
            double fontSize = baseStyle.fontSize ?? 14.0;

            if (attrs != null) {
              if (attrs['bold'] == true) isBold = true;
              if (attrs['italic'] == true) isItalic = true;
              if (attrs['header'] != null) {
                isBold = true;
                final headerLevel = attrs['header'];
                if (headerLevel == 1) {
                  fontSize = 20.0;
                } else if (headerLevel == 2) {
                  fontSize = 18.0;
                } else {
                  fontSize = 16.0;
                }
              }
            }

            spans.add(TextSpan(
              text: insert,
              style: baseStyle.copyWith(
                fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
                fontStyle: isItalic ? FontStyle.italic : baseStyle.fontStyle,
                fontSize: fontSize,
              ),
            ));
          }
        }
      }
      return spans;
    }

    // Format B: EditorJS (JSON Map with 'blocks' key)
    if (decoded is Map && decoded['blocks'] is List) {
      final List<InlineSpan> spans = [];
      final blocks = decoded['blocks'] as List;
      for (final block in blocks) {
        if (block is Map) {
          final type = block['type'] as String?;
          final data = block['data'] as Map?;
          if (data != null) {
            final text = data['text'] as String?;
            if (text != null && text.isNotEmpty) {
              final double fontSize = (type == 'header') ? 18.0 : (baseStyle.fontSize ?? 14.0);
              final FontWeight fontWeight = (type == 'header') ? FontWeight.bold : (baseStyle.fontWeight ?? FontWeight.normal);
              final blockSpans = _parseInlineHtmlAndMarkdown(
                text,
                baseStyle.copyWith(fontSize: fontSize, fontWeight: fontWeight),
              );
              spans.addAll(blockSpans);
              spans.add(const TextSpan(text: '\n\n'));
            }
            final items = data['items'] as List?;
            if (type == 'list' && items != null) {
              for (final item in items) {
                final itemText = item is Map ? item['content']?.toString() : item.toString();
                spans.add(const TextSpan(text: ' • '));
                spans.addAll(_parseInlineHtmlAndMarkdown(itemText ?? '', baseStyle));
                spans.add(const TextSpan(text: '\n'));
              }
              spans.add(const TextSpan(text: '\n'));
            }
          }
        }
      }
      return spans;
    }

    // Format C: General Key-Value Map
    if (decoded is Map) {
      final List<InlineSpan> spans = [];
      decoded.forEach((key, value) {
        spans.add(TextSpan(
          text: '$key: ',
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
        spans.add(TextSpan(
          text: '$value\n\n',
          style: baseStyle,
        ));
      });
      return spans;
    }

    return [];
  }
}
