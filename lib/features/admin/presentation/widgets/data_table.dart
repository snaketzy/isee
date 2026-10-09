import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

typedef RowBuilder<T> = DataRow Function(BuildContext context, T item, bool selected);
typedef SortComparator<T> = int Function(T a, T b);

class DataColumnSpec<T> {
  final String label;
  final double? width;
  final bool numeric;
  final SortComparator<T>? sortComparator;

  const DataColumnSpec({
    required this.label,
    this.width,
    this.numeric = false,
    this.sortComparator,
  });
}

class AdminDataTable<T> extends StatefulWidget {
  final List<T> items;
  final List<DataColumnSpec<T>> columns;
  final RowBuilder<T> rowBuilder;
  final String? headerTitle;
  final Widget? headerAction;
  final ValueChanged<List<T>>? onSelectionChanged;
  final bool selectable;
  final int rowsPerPage;
  final String? noResultText;

  const AdminDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.rowBuilder,
    this.headerTitle,
    this.headerAction,
    this.onSelectionChanged,
    this.selectable = false,
    this.rowsPerPage = 25,
    this.noResultText,
  });

  @override
  State<AdminDataTable<T>> createState() => _AdminDataTableState<T>();
}

class _AdminDataTableState<T> extends State<AdminDataTable<T>> {
  final Set<T> _selected = {};
  int _sortColumnIndex = -1;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    var list = List<T>.from(widget.items);
    if (_sortColumnIndex >= 0 && _sortColumnIndex < widget.columns.length) {
      final col = widget.columns[_sortColumnIndex];
      final cmp = col.sortComparator;
      if (cmp != null) {
        list.sort((a, b) {
          final r = cmp(a, b);
          return _sortAscending ? r : -r;
        });
      }
    }

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                widget.noResultText ?? '暂无数据',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.headerTitle != null || widget.headerAction != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (widget.headerTitle != null)
                    Text(
                      widget.headerTitle!,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const Spacer(),
                  if (widget.headerAction != null) widget.headerAction!,
                ],
              ),
            ),
          if (widget.headerTitle != null)
            const Divider(height: 1, color: AppTheme.divider),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              dataRowMaxHeight: 56,
              headingRowHeight: 48,
              columnSpacing: 20,
              horizontalMargin: 16,
              dividerThickness: 1,
              showCheckboxColumn: widget.selectable,
              sortColumnIndex: _sortColumnIndex >= 0 ? _sortColumnIndex : null,
              sortAscending: _sortAscending,
              columns: widget.columns.asMap().entries.map((e) {
                final i = e.key;
                final c = e.value;
                return DataColumn(
                  label: SizedBox(
                    width: c.width,
                    child: Text(
                      c.label,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  numeric: c.numeric,
                  onSort: c.sortComparator == null
                      ? null
                      : (colIndex, asc) {
                          setState(() {
                            _sortColumnIndex = colIndex;
                            _sortAscending = asc;
                          });
                        },
                );
              }).toList(),
              rows: list.map((item) {
                final selected = _selected.contains(item);
                final row = widget.rowBuilder(context, item, selected);
                if (!widget.selectable) return row;
                return DataRow(
                  selected: selected,
                  onSelectChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selected.add(item);
                      } else {
                        _selected.remove(item);
                      }
                    });
                    widget.onSelectionChanged?.call(List.unmodifiable(_selected));
                  },
                  cells: row.cells,
                  color: selected
                      ? WidgetStateProperty.all(
                          AppTheme.primaryRed.withOpacity(0.08),
                        )
                      : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class DataTextCell extends DataCell {
  DataTextCell(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    TextAlign textAlign = TextAlign.left,
    bool numeric = false,
  }) : super(
          SizedBox(
            width: numeric ? double.infinity : null,
            child: Text(
              text,
              textAlign: numeric ? TextAlign.right : textAlign,
              style: TextStyle(
                color: color ?? AppTheme.textPrimary,
                fontSize: fontSize ?? 13,
                fontWeight: fontWeight ?? FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        );
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusChip.byVariant(String label, StatusVariant variant) {
    switch (variant) {
      case StatusVariant.success:
        return StatusChip(
          label: label,
          color: const Color(0xFF4ADE80),
          icon: Icons.check_circle_rounded,
        );
      case StatusVariant.warning:
        return StatusChip(
          label: label,
          color: const Color(0xFFFBBF24),
          icon: Icons.warning_amber_rounded,
        );
      case StatusVariant.error:
        return StatusChip(
          label: label,
          color: const Color(0xFFF87171),
          icon: Icons.error_rounded,
        );
      case StatusVariant.info:
        return StatusChip(
          label: label,
          color: const Color(0xFF60A5FA),
          icon: Icons.info_outline_rounded,
        );
      case StatusVariant.neutral:
        return StatusChip(
          label: label,
          color: AppTheme.textMuted,
          icon: Icons.circle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusVariant { success, warning, error, info, neutral }
