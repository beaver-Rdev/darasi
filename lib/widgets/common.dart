import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: child,
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
        ),
      );
}

/// جسم الصفحة: قابل للتمرير ومتمركز وبعرض أقصى (متجاوب مع الشاشات الكبيرة).
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 800});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        child: Center(
          child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
        ),
      );
}

/// صف فلاتر أفقي: "الكل" + الخيارات.
class FilterChips extends StatelessWidget {
  const FilterChips({super.key, required this.options, required this.selected, required this.onSelected});
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          ChoiceChip(label: const Text('الكل'), selected: selected == null, onSelected: (_) => onSelected(null)),
          for (final o in options)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: ChoiceChip(label: Text(o), selected: selected == o, onSelected: (_) => onSelected(o)),
            ),
        ]),
      );
}

/// اختيار مادة (مع زر لإضافة مادة جديدة).
class SubjectPicker extends StatelessWidget {
  const SubjectPicker({super.key, required this.selected, required this.onChanged, this.enabled = true});
  final String? selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Wrap(spacing: 8, runSpacing: 4, children: [
      for (final s in app.subjects)
        ChoiceChip(
          label: Text(s),
          selected: selected == s,
          onSelected: enabled ? (bool _) => onChanged(s) : null,
        ),
      if (enabled)
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('مادة'),
          onPressed: () async {
            final v = await promptText(context, 'اسم المادة الجديدة');
            if (v != null && v.isNotEmpty) {
              app.addSubject(v);
              onChanged(v);
            }
          },
        ),
    ]);
  }
}

Future<String?> promptText(BuildContext context, String title, {String? hint}) =>
    showDialog<String>(context: context, builder: (_) => _PromptDialog(title: title, hint: hint));

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({required this.title, this.hint});
  final String title;
  final String? hint;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(controller: _c, autofocus: true, decoration: InputDecoration(hintText: widget.hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, _c.text.trim()), child: const Text('حفظ')),
        ],
      );
}

Future<bool> confirm(BuildContext context, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
      ],
    ),
  );
  return ok ?? false;
}
