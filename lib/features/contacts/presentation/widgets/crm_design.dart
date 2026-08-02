import 'package:flutter/material.dart';

const crmPanelWidth = 320.0;
const crmPanelPadding = 16.0;
const crmHeaderHeight = 32.0;
const crmRowHeight = 34.0;
const crmCellPadding = 8.0;

bool crmIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color crmPageBackground(bool dark) =>
    dark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);

Color crmSurfaceColor(bool dark) =>
    dark ? const Color(0xFF171717) : const Color(0xFFFCFCFC);

Color crmElevatedSurfaceColor(bool dark) =>
    dark ? const Color(0xFF1D1D1D) : Colors.white;

Color crmBorderColor(bool dark) =>
    dark ? const Color(0xFF2A2A2A) : const Color(0xFFEBEBE8);

Color crmMutedTextColor(bool dark) =>
    dark ? const Color(0xFF8F8F8F) : const Color(0xFF8F8F8F);

Color crmHeaderTextColor(bool dark) =>
    dark ? const Color(0xFF969696) : const Color(0xFF8D8D8D);

Color crmBodyTextColor(bool dark) =>
    dark ? const Color(0xFFE1E1E1) : const Color(0xFF505050);

Color crmHoverColor(bool dark) =>
    dark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8F8F6);

Color crmPanelBackground(bool dark) =>
    dark ? const Color(0xFF141414) : const Color(0xFFFCFCFC);

BoxDecoration crmSurfaceDecoration(bool dark, {double radius = 14}) {
  return BoxDecoration(
    color: crmElevatedSurfaceColor(dark),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: crmBorderColor(dark)),
  );
}

Widget crmHeaderText(String text, bool dark, {bool sortable = false}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        text.toUpperCase(),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: crmHeaderTextColor(dark),
          letterSpacing: 0.3,
        ),
      ),
      if (sortable)
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(
            Icons.unfold_more_rounded,
            size: 12,
            color: crmHeaderTextColor(dark).withValues(alpha: 0.5),
          ),
        ),
    ],
  );
}

Text crmBodyText(String text, bool dark,
    {FontWeight weight = FontWeight.w400}) {
  return Text(
    text,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: 12,
      fontWeight: weight,
      color: crmBodyTextColor(dark),
    ),
  );
}

Text crmMutedText(String text, bool dark) {
  return Text(
    text,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: crmMutedTextColor(dark),
    ),
  );
}

class CrmChip extends StatelessWidget {
  final String label;
  final bool dark;
  final Color? accent;

  const CrmChip({
    super.key,
    required this.label,
    required this.dark,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final outline = accent ?? crmBorderColor(dark);
    final bg = accent != null
        ? accent!.withValues(alpha: dark ? 0.14 : 0.08)
        : (dark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF6F6F4));
    final fg = accent ?? crmBodyTextColor(dark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: outline.withValues(alpha: accent != null ? 0.3 : 0.8)),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class CrmAvatarBadge extends StatelessWidget {
  final String seed;
  final Color accent;
  final double size;

  const CrmAvatarBadge({
    super.key,
    required this.seed,
    required this.accent,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final letter = seed.isEmpty ? '?' : seed.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size <= 18 ? 5 : 10),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: accent,
          fontSize: size <= 18 ? 9 : 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class CrmSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool dark;
  final String hintText;

  const CrmSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.dark,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style:
          TextStyle(fontSize: 13, color: dark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 13, color: crmMutedTextColor(dark)),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: crmMutedTextColor(dark),
        ),
        filled: true,
        fillColor: dark ? const Color(0xFF1B1B1B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: crmBorderColor(dark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: crmBorderColor(dark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
      ),
    );
  }
}

class CrmSurface extends StatelessWidget {
  final Widget child;
  final bool dark;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const CrmSurface({
    super.key,
    required this.child,
    required this.dark,
    this.padding,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: crmSurfaceDecoration(dark, radius: radius),
      child: child,
    );
  }
}

class CrmFieldPanel extends StatelessWidget {
  final Widget child;
  final bool dark;
  final EdgeInsetsGeometry? padding;
  final bool compact;

  const CrmFieldPanel({
    super.key,
    required this.child,
    required this.dark,
    this.padding,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? null : crmPanelWidth,
      padding: padding,
      decoration: BoxDecoration(
        color: crmPanelBackground(dark),
        border: Border(
          right: BorderSide(color: crmBorderColor(dark)),
          top: compact
              ? BorderSide(color: crmBorderColor(dark))
              : BorderSide.none,
          left: compact
              ? BorderSide(color: crmBorderColor(dark))
              : BorderSide.none,
          bottom: compact
              ? BorderSide(color: crmBorderColor(dark))
              : BorderSide.none,
        ),
        borderRadius: compact ? BorderRadius.circular(16) : BorderRadius.zero,
      ),
      child: child,
    );
  }
}

class CrmSectionBlock extends StatelessWidget {
  final String title;
  final bool dark;
  final Widget child;
  final Widget? trailing;

  const CrmSectionBlock({
    super.key,
    required this.title,
    required this.dark,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: crmMutedTextColor(dark),
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class CrmTableViewport extends StatefulWidget {
  final double minWidth;
  final Widget header;
  final Widget body;

  const CrmTableViewport({
    super.key,
    required this.minWidth,
    required this.header,
    required this.body,
  });

  @override
  State<CrmTableViewport> createState() => _CrmTableViewportState();
}

class _CrmTableViewportState extends State<CrmTableViewport> {
  late final ScrollController _horizontalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showHorizontal = constraints.maxWidth < widget.minWidth;
        final width = showHorizontal ? widget.minWidth : constraints.maxWidth;
        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: showHorizontal,
          interactive: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  widget.header,
                  Expanded(child: widget.body),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CrmInlineTitle extends StatefulWidget {
  final String value;
  final bool dark;
  final String placeholder;
  final Future<void> Function(String value) onSave;

  const CrmInlineTitle({
    super.key,
    required this.value,
    required this.dark,
    required this.placeholder,
    required this.onSave,
  });

  @override
  State<CrmInlineTitle> createState() => _CrmInlineTitleState();
}

class _CrmInlineTitleState extends State<CrmInlineTitle> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late String _lastSaved;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lastSaved = widget.value;
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode()
      ..addListener(() {
        if (!_focusNode.hasFocus) _saveIfNeeded();
      });
  }

  @override
  void didUpdateWidget(covariant CrmInlineTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value != _lastSaved) {
      _lastSaved = widget.value;
      _controller.text = widget.value;
    }
  }

  Future<void> _saveIfNeeded() async {
    final next = _controller.text.trim();
    if (next.isEmpty || next == _lastSaved) return;
    setState(() => _saving = true);
    await widget.onSave(next);
    if (!mounted) return;
    _lastSaved = next;
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: crmBodyTextColor(widget.dark),
          ),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: widget.placeholder,
            hintStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: crmMutedTextColor(widget.dark),
            ),
          ),
          onSubmitted: (_) => _focusNode.unfocus(),
        ),
        if (_saving)
          Positioned(
            right: 0,
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class CrmInlineField extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool dark;
  final String placeholder;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final bool treatEmptyAsNull;
  final Future<void> Function(String? value) onSave;

  const CrmInlineField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.dark,
    required this.placeholder,
    required this.onSave,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.treatEmptyAsNull = true,
  });

  @override
  State<CrmInlineField> createState() => _CrmInlineFieldState();
}

class _CrmInlineFieldState extends State<CrmInlineField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late String _lastSaved;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lastSaved = widget.value;
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode()
      ..addListener(() {
        if (!_focusNode.hasFocus) _saveIfNeeded();
      });
  }

  @override
  void didUpdateWidget(covariant CrmInlineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value != _lastSaved) {
      _lastSaved = widget.value;
      _controller.text = widget.value;
    }
  }

  Future<void> _saveIfNeeded() async {
    final trimmed = _controller.text.trim();
    final compare = widget.treatEmptyAsNull && trimmed.isEmpty ? '' : trimmed;
    if (compare == _lastSaved) return;
    setState(() => _saving = true);
    await widget.onSave(
      widget.treatEmptyAsNull && trimmed.isEmpty ? null : trimmed,
    );
    if (!mounted) return;
    _lastSaved = compare;
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines > 1;
    return Padding(
      padding: EdgeInsets.only(bottom: multiline ? 10 : 0),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: multiline ? 10 : 0),
            child: Icon(widget.icon,
                size: 15, color: crmMutedTextColor(widget.dark)),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: EdgeInsets.only(top: multiline ? 8 : 0),
            child: SizedBox(
              width: 72,
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: crmMutedTextColor(widget.dark),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  minLines: widget.minLines,
                  maxLines: widget.maxLines,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: crmBodyTextColor(widget.dark),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: widget.placeholder,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: crmMutedTextColor(widget.dark),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: multiline ? 8 : 0,
                    ),
                  ),
                  onSubmitted: (_) => _focusNode.unfocus(),
                ),
                if (_saving)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CrmInlineDropdownField<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T value;
  final bool dark;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const CrmInlineDropdownField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.dark,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: crmMutedTextColor(dark)),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: crmMutedTextColor(dark)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: crmBodyTextColor(dark),
            ),
            icon:
                Icon(Icons.expand_more_rounded, color: crmMutedTextColor(dark)),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────
// Deletion helpers & components
// ────────────────────────────────────────────

const _crmDeleteRed = Color(0xFFEF5350);

Future<bool?> crmDeleteConfirmation({
  required BuildContext context,
  required String title,
  required VoidCallback onConfirm,
  required bool dark,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: crmBodyTextColor(dark),
        ),
      ),
      backgroundColor: crmElevatedSurfaceColor(dark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: crmBorderColor(dark)),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: OutlinedButton.styleFrom(
            foregroundColor: crmMutedTextColor(dark),
            side: BorderSide(color: crmBorderColor(dark)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(ctx, true);
          },
          style: TextButton.styleFrom(
            backgroundColor: _crmDeleteRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

class CrmDeleteActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final bool dark;
  final Color primary;
  final VoidCallback? onCancel;

  const CrmDeleteActionBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    required this.dark,
    required this.primary,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: dark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          if (onCancel != null)
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: crmMutedTextColor(dark),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          const Spacer(),
          Text(
            '$selectedCount selected',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: primary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              crmDeleteConfirmation(
                context: context,
                title: selectedCount == 1
                    ? 'Delete 1 item?'
                    : 'Delete $selectedCount items?',
                onConfirm: onDelete,
                dark: dark,
              );
            },
            icon: const Icon(Icons.delete_outline_rounded),
            color: _crmDeleteRed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            iconSize: 18,
          ),
        ],
      ),
    );
  }
}

class CrmSwipeDismissible extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;
  final bool dark;
  final Key? dismissKey;

  const CrmSwipeDismissible({
    super.key,
    required this.child,
    required this.onDelete,
    required this.dark,
    this.dismissKey,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: dismissKey ?? UniqueKey(),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.5},
      confirmDismiss: (_) async {
        final confirmed = await crmDeleteConfirmation(
          context: context,
          title: 'Delete this item?',
          onConfirm: () {},
          dark: dark,
        );
        if (confirmed == true) {
          onDelete();
          return true;
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: _crmDeleteRed,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      child: child,
    );
  }
}
