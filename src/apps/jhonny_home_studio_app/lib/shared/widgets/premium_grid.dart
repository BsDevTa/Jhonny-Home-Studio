import 'package:flutter/material.dart';

class PremiumGrid extends StatelessWidget {
  const PremiumGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.minItemWidth,
    this.maxColumns = 6,
    this.spacing = 14,
    this.runSpacing = 14,
    this.childAspectRatio = 0.72,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  int _columnsFor(double width) {
    final columns = (width / minItemWidth).floor();
    return columns.clamp(1, maxColumns);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
