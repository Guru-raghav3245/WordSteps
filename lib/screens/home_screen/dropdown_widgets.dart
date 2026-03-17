import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/questions/content_type.dart';

class GameModeDropdown extends ConsumerWidget {
  final String selectedMode;
  final ValueChanged<String> onChanged;

  const GameModeDropdown({
    required this.selectedMode,
    required this.onChanged,
    super.key,
  });

  String _getDisplayName(String mode) {
    return mode == 'read' ? 'Listen Mode' : 'Read Mode';
  }

  IconData _getIcon(String mode) {
    return mode == 'read' ? Icons.headphones : Icons.menu_book;
  }

  void _showGridSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _GameModeGridSheet(
        selectedMode: selectedMode,
        onSelect: (mode) {
          onChanged(mode);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;
    const color = Colors.deepPurple;

    return InkWell(
      onTap: () => _showGridSheet(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: isTablet ? 65 : 60,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(_getIcon(selectedMode), size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Game Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 12 : 10,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    _getDisplayName(selectedMode),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 16 : 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}

class _GameModeGridSheet extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onSelect;

  const _GameModeGridSheet(
      {required this.selectedMode, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modes = [
      {'value': 'read', 'label': 'Listen Mode', 'icon': Icons.headphones},
      {'value': 'listen', 'label': 'Read Mode', 'icon': Icons.menu_book},
    ];

    return Container(
      padding: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Select Game Mode',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: modes.map((mode) {
              final isSelected = mode['value'] == selectedMode;
              const color = Colors.deepPurple;

              return GestureDetector(
                onTap: () => onSelect(mode['value'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: MediaQuery.of(context).size.width * 0.4,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isSelected ? color : color.withOpacity(0.3),
                        width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(mode['icon'] as IconData,
                          size: 32, color: isSelected ? Colors.white : color),
                      const SizedBox(height: 8),
                      Text(
                        mode['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class ContentTypeDropdown extends ConsumerWidget {
  final ContentType selectedType;
  final ValueChanged<ContentType> onChanged;

  const ContentTypeDropdown({
    required this.selectedType,
    required this.onChanged,
    super.key,
  });

  Color _getColor(ContentType type) {
    final name = type.name;
    if (name.contains('_') ||
        name == 'narrative' ||
        name == 'action' ||
        name == 'nature' ||
        name == 'descriptive') return Colors.blue;
    int length = int.tryParse(name) ?? 0;
    if (length <= 6) return Colors.green;
    if (length <= 10) return Colors.orange;
    return Colors.red;
  }

  void _showGridSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContentTypeGridSheet(
        selectedType: selectedType,
        onSelect: (type) {
          onChanged(type);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;
    final color = _getColor(selectedType);

    return InkWell(
      onTap: () => _showGridSheet(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: isTablet ? 65 : 60,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(Icons.subject, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Content Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 12 : 10,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    selectedType.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 15 : 13,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}

class _ContentTypeGridSheet extends StatelessWidget {
  final ContentType selectedType;
  final ValueChanged<ContentType> onSelect;

  const _ContentTypeGridSheet(
      {required this.selectedType, required this.onSelect});

  static const Map<String, List<ContentType>> _groups = {
    'Short Words (3-6 letters)': [
      ContentType.wordLength3,
      ContentType.wordLength4,
      ContentType.wordLength5,
      ContentType.wordLength6,
    ],
    'Medium Words (7-10 letters)': [
      ContentType.wordLength7,
      ContentType.wordLength8,
      ContentType.wordLength9,
      ContentType.wordLength10,
    ],
    'Long Words (11-14 letters)': [
      ContentType.wordLength11,
      ContentType.wordLength12,
      ContentType.wordLength13,
      ContentType.wordLength14,
    ],
    'Sentences': [
      ContentType.basicSV,
      ContentType.cvcSimple,
      ContentType.descriptive,
      ContentType.actionSentences,
      ContentType.natureScene,
      ContentType.narrativeSentences,
    ],
  };

  Color _getColor(ContentType type) {
    final name = type.name;
    if (name.contains('_') ||
        name == 'narrative' ||
        name == 'action' ||
        name == 'nature' ||
        name == 'descriptive') return Colors.blue;
    int length = int.tryParse(name) ?? 0;
    if (length <= 6) return Colors.green;
    if (length <= 10) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Select Content',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _groups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final groupName = _groups.keys.elementAt(index);
                final items = _groups[groupName]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.75, // ← Increased height (was 2.2)
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final type = items[i];
                        final isSelected = type == selectedType;
                        final color = _getColor(type);
                        final hasDescription = type.description.isNotEmpty;

                        return InkWell(
                          onTap: () => onSelect(type),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8), // ← More padding
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? color : color.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    isSelected ? color : color.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  type.displayName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: hasDescription ? 12 : 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : color,
                                  ),
                                ),
                                if (hasDescription) ...[
                                  const SizedBox(
                                      height: 4), // ← Slightly more space
                                  Text(
                                    type.description,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w400,
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.9)
                                          : color.withOpacity(0.7),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
