import '../models/transaction_model.dart';

/// Gelir/gider toplamları (ana sayfa ve testler aynı hesabı kullanır)
class Balance {
  /// Verilen ayın (varsayılan: bu ay) gelir veya gider toplamı.
  /// Ayın 1'i dahil, sonraki ayın 1'i hariç.
  static double monthTotal(
    List<TransactionModel> transactions,
    TransactionType type, {
    DateTime? month,
  }) {
    final m = month ?? DateTime.now();
    final start = DateTime(m.year, m.month);
    final end = DateTime(m.year, m.month + 1);
    return transactions
        .where((t) => t.type == type && !t.date.isBefore(start) && t.date.isBefore(end))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Tüm zamanların net bakiyesi: toplam gelir − toplam gider
  static double net(List<TransactionModel> transactions) => transactions.fold(
        0.0,
        (sum, t) => t.type == TransactionType.income ? sum + t.amount : sum - t.amount,
      );
}
