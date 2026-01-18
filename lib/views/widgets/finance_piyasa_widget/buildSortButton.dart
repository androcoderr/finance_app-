import 'package:flutter/material.dart';

import '../../../view_model/finance_view_model.dart';

Widget buildSortButton(
  String title,
  SortType sortType,
  FinanceViewModel viewModel,
) {
  bool isActive = viewModel.currentSortType == sortType;

  return Padding(
    padding: EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (isActive) ...[
            SizedBox(width: 4),
            Icon(
              viewModel.isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
            ),
          ],
        ],
      ),
      selected: isActive,
      onSelected: (_) => viewModel.sortBy(sortType),
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade700,
    ),
  );
}
