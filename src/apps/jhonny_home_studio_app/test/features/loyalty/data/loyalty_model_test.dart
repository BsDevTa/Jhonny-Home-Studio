import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny_home_studio_app/features/loyalty/data/loyalty_model.dart';

void main() {
  test('converte fidelidade e calcula progresso até próximo nível', () {
    final loyalty = LoyaltyModel.fromJson({
      'customerId': 'customer-1',
      'points': 150,
      'level': 'Gold',
      'nextLevel': 'Platinum',
      'pointsToNextLevel': 150,
      'benefits': ['Benefício premium'],
      'recentTransactions': [
        {
          'id': 'transaction-1',
          'appointmentId': 'appointment-1',
          'points': 25,
          'description': 'Atendimento concluído',
          'createdAt': '2026-06-01T10:00:00Z',
        },
      ],
    });

    expect(loyalty.points, 150);
    expect(loyalty.level, 'Gold');
    expect(loyalty.progress, 0.25);
    expect(loyalty.recentTransactions.single.points, 25);
  });

  test('mantém fallback Bronze antes do primeiro atendimento', () {
    expect(LoyaltyModel.empty.level, 'Bronze');
    expect(LoyaltyModel.empty.points, 0);
    expect(LoyaltyModel.empty.progress, 0);
  });
}
