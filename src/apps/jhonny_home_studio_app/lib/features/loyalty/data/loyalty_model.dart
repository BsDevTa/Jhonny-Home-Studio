class LoyaltyModel {
  const LoyaltyModel({
    required this.customerId,
    required this.points,
    required this.level,
    required this.nextLevel,
    required this.pointsToNextLevel,
    required this.benefits,
    required this.recentTransactions,
  });

  final String customerId;
  final int points;
  final String level;
  final String nextLevel;
  final int pointsToNextLevel;
  final List<LoyaltyTransactionModel> recentTransactions;
  final List<String> benefits;

  static const empty = LoyaltyModel(
    customerId: '',
    points: 0,
    level: 'Bronze',
    nextLevel: 'Gold',
    pointsToNextLevel: 100,
    benefits: ['Acesso ao cartão fidelidade'],
    recentTransactions: [],
  );

  factory LoyaltyModel.fromJson(Map<String, dynamic> json) {
    final benefits = json['benefits'];
    final transactions = json['recentTransactions'];

    return LoyaltyModel(
      customerId: _readString(json, 'customerId'),
      points: _readInt(json, 'points'),
      level: _readString(json, 'level', fallback: 'Bronze'),
      nextLevel: _readString(json, 'nextLevel'),
      pointsToNextLevel: _readInt(json, 'pointsToNextLevel'),
      benefits: benefits is List
          ? benefits.map((item) => item.toString()).toList(growable: false)
          : const [],
      recentTransactions: transactions is List
          ? transactions
                .whereType<Map<String, dynamic>>()
                .map(LoyaltyTransactionModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  double get progress {
    final currentLevelStart = switch (level.toLowerCase()) {
      'gold' => 100,
      'platinum' => 300,
      'diamond' => 600,
      _ => 0,
    };
    final nextLevelStart = switch (nextLevel.toLowerCase()) {
      'gold' => 100,
      'platinum' => 300,
      'diamond' => 600,
      _ => currentLevelStart,
    };

    if (nextLevelStart <= currentLevelStart) {
      return 1;
    }

    return ((points - currentLevelStart) / (nextLevelStart - currentLevelStart))
        .clamp(0, 1)
        .toDouble();
  }
}

class LoyaltyTransactionModel {
  const LoyaltyTransactionModel({
    required this.id,
    required this.appointmentId,
    required this.points,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String appointmentId;
  final int points;
  final String description;
  final DateTime? createdAt;

  factory LoyaltyTransactionModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransactionModel(
      id: _readString(json, 'id'),
      appointmentId: _readString(json, 'appointmentId'),
      points: _readInt(json, 'points'),
      description: _readString(json, 'description'),
      createdAt: DateTime.tryParse(_readString(json, 'createdAt')),
    );
  }
}

String _readString(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final value = json[key]?.toString().trim() ?? '';
  return value.isEmpty ? fallback : value;
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
