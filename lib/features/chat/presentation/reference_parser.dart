import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Regex patterns for locating reference markers in AI responses.
///
/// Supported formats:
/// - `[ref:note_id]` — text reference (anchors to a note or chat message)
/// - `[ref:sql_result]` — structured data reference (renders as DataCard)
final _refPattern = RegExp(r'\[ref:([^\]]+)\]');

/// Callback when a reference is tapped.
typedef ReferenceTapCallback = void Function(String refId);

/// Post-processes AI response text to render references as clickable links.
///
/// In the AI system prompt, the LLM is instructed to mark references as
/// `[ref:xxx]`. This parser detects those markers in the response text
/// and replaces them with visual badges that can be tapped to navigate
/// to the source content.
class ReferenceParser {
  /// Parse a raw AI response and return a list of [RefSegment]s.
  ///
  /// Segments alternate between plain text and reference markers,
  /// making it easy to compose into a RichText or Markdown builder.
  static List<RefSegment> parse(String text) {
    final segments = <RefSegment>[];
    var lastEnd = 0;

    for (final match in _refPattern.allMatches(text)) {
      // Text before this reference
      if (match.start > lastEnd) {
        segments.add(RefSegment.text(text.substring(lastEnd, match.start)));
      }
      // The reference itself
      segments.add(RefSegment.ref(match.group(1)!));
      lastEnd = match.end;
    }

    // Remaining text after last reference
    if (lastEnd < text.length) {
      segments.add(RefSegment.text(text.substring(lastEnd)));
    }

    return segments;
  }

  /// Remove all reference markers from text, leaving clean plain text.
  static String clean(String text) {
    return text.replaceAll(_refPattern, '');
  }

  /// Check if the text contains any reference markers.
  static bool hasReferences(String text) {
    return _refPattern.hasMatch(text);
  }

  /// Build an inline RichText widget from parsed segments.
  ///
  /// References are rendered as tappable colored badges.
  static Widget buildRichText(
    BuildContext context,
    String text, {
    ReferenceTapCallback? onTap,
    TextStyle? baseStyle,
  }) {
    final segments = parse(text);
    final spans = <InlineSpan>[];
    final color = Theme.of(context).colorScheme.primary;

    for (final seg in segments) {
      if (seg.isRef) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => onTap?.call(seg.refId!),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                '[ref:${seg.refId}]',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(text: seg.text, style: baseStyle));
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  /// Extend MarkdownBody with reference parsing.
  ///
  /// Returns a map of [MarkdownElementBuilder]s that can be passed
  /// to MarkdownBody's `builders` parameter.
  static Map<String, MarkdownElementBuilder> getMarkdownBuilders({
    ReferenceTapCallback? onTap,
  }) {
    return {
      'ref': _RefElementBuilder(onTap: onTap),
    };
  }

  /// Post-process the Markdown AST to add reference handling.
  ///
  /// This is called as an md.InlineSyntax to be used with MarkdownBody's
  /// `inlineSyntaxes` parameter.
  static List<md.InlineSyntax> get inlineSyntaxes => [
        _RefInlineSyntax(),
      ];
}

/// A single segment of text — either plain text or a reference marker.
class RefSegment {
  final String? text;
  final String? refId;

  RefSegment.text(this.text) : refId = null;
  RefSegment.ref(this.refId) : text = null;

  bool get isRef => refId != null;
}

/// Custom inline syntax to handle [ref:xxx] markers in Markdown.
class _RefInlineSyntax extends md.InlineSyntax {
  _RefInlineSyntax() : super(r'\[ref:([^\]]+)\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final refId = match.group(1)!;
    parser.addNode(md.Element('ref', [md.Text(refId)]));
    return true;
  }
}

/// MarkdownElementBuilder that renders `[ref:xxx]` as a tappable badge.
class _RefElementBuilder extends MarkdownElementBuilder {
  final ReferenceTapCallback? onTap;

  _RefElementBuilder({this.onTap});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final refId = element.textContent;
    final color = preferredStyle?.color ?? Colors.blue;

    return GestureDetector(
      onTap: () => onTap?.call(refId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '[ref:$refId]',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
