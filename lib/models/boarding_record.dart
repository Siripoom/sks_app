enum BoardingAction { boarded, alighted }

class BoardingRecord {
  final String childId;
  final String busId;
  final BoardingAction action;
  final DateTime timestamp;

  const BoardingRecord({
    required this.childId,
    required this.busId,
    required this.action,
    required this.timestamp,
  });

  BoardingRecord copyWith({
    String? childId,
    String? busId,
    BoardingAction? action,
    DateTime? timestamp,
  }) {
    return BoardingRecord(
      childId: childId ?? this.childId,
      busId: busId ?? this.busId,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
