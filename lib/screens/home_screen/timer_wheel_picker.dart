// File: lib1/screens/home_screen/timer_wheel_picker.dart
import 'dart:async';
import 'package:flutter/material.dart';

class TimeWheelPicker extends StatefulWidget {
  final int initialIndex;
  final Function(int) onConfirm;

  const TimeWheelPicker({
    super.key,
    required this.initialIndex,
    required this.onConfirm,
  });

  @override
  _TimeWheelPickerState createState() => _TimeWheelPickerState();
}

class _TimeWheelPickerState extends State<TimeWheelPicker> {
  late int _selectedIndex;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Set Time Limit',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose any time limit for your session.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 50,
              diameterRatio: 1.5,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                _startInactivityTimer();
              },
              controller:
                  FixedExtentScrollController(initialItem: _selectedIndex),
              childDelegate: ListWheelChildListDelegate(
                children: List.generate(
                  61, // 0 to 60 minutes
                  (index) {
                    final isSelected = index == _selectedIndex;
                    final displayText = index == 0
                        ? 'No Limit'
                        : '$index minute${index == 1 ? '' : 's'}';

                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          displayText,
                          style: TextStyle(
                            fontSize: 20,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodyLarge?.color,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _startInactivityTimer();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(_selectedIndex);
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
