import 'package:equatable/equatable.dart';

class GoalModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    required this.createdAt,
  });

  double get progress => savedAmount / targetAmount;
  bool get isCompleted => savedAmount >= targetAmount;

  factory GoalModel.fromMap(Map<String, dynamic> m) => GoalModel(
    id: m['id'], userId: m['user_id'], name: m['name'],
    emoji: m['emoji'] ?? '🎯',
    targetAmount: (m['target_amount'] as num).toDouble(),
    savedAmount: (m['saved_amount'] as num).toDouble(),
    deadline: m['deadline'] != null ? DateTime.parse(m['deadline']) : null,
    createdAt: DateTime.parse(m['created_at']),
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'user_id': userId, 'name': name, 'emoji': emoji,
    'target_amount': targetAmount, 'saved_amount': savedAmount,
    'deadline': deadline?.toIso8601String(), 'created_at': createdAt.toIso8601String(),
  };

  GoalModel copyWith({double? savedAmount}) => GoalModel(
    id: id, userId: userId, name: name, emoji: emoji,
    targetAmount: targetAmount, savedAmount: savedAmount ?? this.savedAmount,
    deadline: deadline, createdAt: createdAt,
  );

  @override
  List<Object?> get props => [id, userId, name];
}
