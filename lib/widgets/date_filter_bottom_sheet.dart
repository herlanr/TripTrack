import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Modal Bottom Sheet zur komfortablen Datumsauswahl (Schnellauswahl-Chips & von/bis Datumswähler).
class DateFilterBottomSheet extends StatefulWidget {
  /// Erstellt die DateFilterBottomSheet-Instanz.
  const DateFilterBottomSheet({super.key, this.initialRange});

  /// Der aktuell gesetzte Datumsbereich
  final DateTimeRange? initialRange;

  /// Öffnet das Bottom Sheet zur Datumsauswahl.
  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTimeRange? initialRange,
  }) {
    return showModalBottomSheet<DateTimeRange?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DateFilterBottomSheet(initialRange: initialRange),
    );
  }

  @override
  State<DateFilterBottomSheet> createState() => _DateFilterBottomSheetState();
}

class _DateFilterBottomSheetState extends State<DateFilterBottomSheet> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _startDate = widget.initialRange!.start;
      _endDate = widget.initialRange!.end;
    }
  }

  void _applyPreset(DateTime start, DateTime end) {
    setState(() {
      _startDate = DateTime(start.year, start.month, start.day);
      _endDate = DateTime(end.year, end.month, end.day);
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(now.year + 5, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _submit() {
    final start = _startDate;
    final end = _endDate;

    if (start == null && end == null) {
      Navigator.of(context).pop(null);
      return;
    }

    final effectiveStart = start ?? end ?? DateTime(2020, 1, 1);
    final effectiveEnd = end ?? start ?? DateTime.now();

    Navigator.of(context).pop(
      DateTimeRange(
        start: effectiveStart.isAfter(effectiveEnd)
            ? effectiveEnd
            : effectiveStart,
        end: effectiveStart.isAfter(effectiveEnd)
            ? effectiveStart
            : effectiveEnd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart =
        todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final last30Start = todayStart.subtract(const Duration(days: 30));
    final yearStart = DateTime(now.year, 1, 1);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Datumsfilter',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(widget.initialRange),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Schnellauswahl Title
            Text(
              'Schnellauswahl',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),

            // Schnellauswahl Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.today_rounded, size: 16),
                  label: const Text('Heute'),
                  onPressed: () => _applyPreset(todayStart, now),
                ),
                ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 16),
                  label: const Text('Diese Woche'),
                  onPressed: () => _applyPreset(weekStart, now),
                ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_view_month_rounded, size: 16),
                  label: const Text('Diesen Monat'),
                  onPressed: () => _applyPreset(monthStart, now),
                ),
                ActionChip(
                  avatar: const Icon(Icons.history_toggle_off_rounded, size: 16),
                  label: const Text('Letzte 30 Tage'),
                  onPressed: () => _applyPreset(last30Start, now),
                ),
                ActionChip(
                  avatar: const Icon(Icons.event_note_rounded, size: 16),
                  label: const Text('Dieses Jahr'),
                  onPressed: () => _applyPreset(yearStart, now),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Benutzerdefinierter Zeitraum Title
            Text(
              'Benutzerdefinierter Zeitraum',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),

            // Von / Bis Selector Cards
            Row(
              children: [
                // Von
                Expanded(
                  child: InkWell(
                    onTap: _pickStartDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _startDate != null
                              ? AppTheme.primaryGreen
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Von (Start)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _startDate != null
                                      ? formatDate(_startDate!)
                                      : 'Auswählen',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _startDate != null
                                        ? AppTheme.textDark
                                        : Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Bis
                Expanded(
                  child: InkWell(
                    onTap: _pickEndDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _endDate != null
                              ? AppTheme.primaryGreen
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bis (Ende)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.event_rounded,
                                size: 16,
                                color: AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _endDate != null
                                      ? formatDate(_endDate!)
                                      : 'Auswählen',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _endDate != null
                                        ? AppTheme.textDark
                                        : Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppTheme.stopRed,
                      side: const BorderSide(
                        color: AppTheme.stopRed,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      Navigator.of(context).pop(null);
                    },
                    child: const Text(
                      'Zurücksetzen',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submit,
                    child: const Text(
                      'Anwenden',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
