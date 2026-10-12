import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../transaction_detail_page.dart';
import 'ui/ui.dart';

/// İşlem satırı (ana sayfa "Son işlemler" ve "Tüm işlemler"); dokununca detay
class TransactionRow extends StatelessWidget {
  final TransactionModel t;
  final String? categoryName;
  final String subtitle;
  final bool hidden;

  const TransactionRow({
    required this.t,
    required this.categoryName,
    required this.subtitle,
    required this.hidden,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = t.description.trim().isNotEmpty
        ? t.description.trim()
        : (categoryName ?? 'İşlem');
    final meta = t.description.trim().isNotEmpty && categoryName != null
        ? '$categoryName · $subtitle'
        : subtitle;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TransactionDetailPage(transaction: t)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ToneIcon.category(categoryName, size: 42),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.textMuted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            AmountLabel(
              amount: t.amount,
              isIncome: t.type == TransactionType.income,
              hidden: hidden,
            ),
          ],
        ),
      ),
    );
  }
}
