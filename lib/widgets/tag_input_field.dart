import 'package:flutter/material.dart';

class TagInputField extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  const TagInputField({super.key, required this.tags, required this.onChanged});

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _ctrl = TextEditingController();

  void _add() {
    final tag = _ctrl.text.trim().toLowerCase();
    if (tag.isEmpty || widget.tags.contains(tag)) {
      _ctrl.clear();
      return;
    }
    widget.onChanged([...widget.tags, tag]);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5D3891);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Add tag (e.g. groceries)',
                  filled: true,
                  fillColor: const Color(0xFFF8F6FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: primary),
              onPressed: _add,
            ),
          ],
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.tags
                .map((tag) => Chip(
                      label: Text(tag,
                          style: const TextStyle(
                              fontSize: 12, color: primary)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () {
                        widget.onChanged(
                            widget.tags.where((t) => t != tag).toList());
                      },
                      backgroundColor: primary.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
