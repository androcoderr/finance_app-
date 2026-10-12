import 'package:flutter_test/flutter_test.dart';
import 'package:test_borsa/models/goal_model.dart';
import 'package:test_borsa/models/transaction_model.dart';
import 'package:test_borsa/models/user_model.dart';
import 'package:test_borsa/services/app_update_service.dart';

void main() {
  test('Goal: son tarih goal_dates listesindeki en yeni tarih', () {
    final g = Goal.fromJson({
      'id': 'g1',
      'name': 'Tatil',
      'target_amount': 20000,
      'current_amount': 5000,
      'created_at': '2026-01-01T00:00:00',
      'goal_dates': [
        {'date': '2026-06-01'},
        {'date': '2026-12-31'},
        {'date': 'bozuk'},
      ],
    });
    expect(g.targetDate, DateTime(2026, 12, 31));
    expect(g.progress, 0.25);
  });

  test('Goal: hedef 0 iken ilerleme 0, fazlası 1 ile sınırlı', () {
    Goal make(num target, num current) => Goal.fromJson({
          'target_amount': target,
          'current_amount': current,
          'created_at': '2026-01-01T00:00:00',
        });
    expect(make(0, 100).progress, 0);
    expect(make(100, 250).progress, 1);
    expect(make(100, 0).targetDate, isNull);
  });

  test('User.toJson şifreyi cihaza yazmaz', () {
    final u = User.fromJson({
      'id': 'u1',
      'name': 'Deneme',
      'email': 'deneme@example.com',
      'password': 'gizli',
    });
    final json = u.toJson();
    expect(json.containsKey('password'), isFalse);
    expect(json['email'], 'deneme@example.com');
  });

  test('TransactionModel: tür ve tutar', () {
    final t = TransactionModel.fromJson({
      'id': 't1',
      'user_id': 'u1',
      'amount': 6500,
      'category_id': 'c1',
      'date': '2026-10-09T10:30:00',
      'type': 'income',
    });
    expect(t.amount, 6500.0);
    expect(t.type, TransactionType.income);
    expect(t.toApiJson()['type'], 'income');
  });

  test('AppConfig: zorunlu / isteğe bağlı güncelleme', () {
    final c = AppConfig.fromJson({
      'update_required': true,
      'update_available': true,
      'store_url': 'https://play.google.com/store/apps/details?id=com.finanscepte.app',
    });
    expect(c.updateRequired, isTrue);
    expect(c.updateAvailable, isTrue);
    final empty = AppConfig.fromJson({});
    expect(empty.updateRequired, isFalse);
    expect(empty.storeUrl, contains('com.finanscepte.app'));
  });
}
