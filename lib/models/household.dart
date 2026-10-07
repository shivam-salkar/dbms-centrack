class Household {
  final String id;
  final String headName;
  final int memberCount;
  final String address;
  final bool phase1Complete;
  final bool phase2Complete;

  final String? dbId;

  const Household({
    required this.id,
    required this.headName,
    required this.memberCount,
    required this.address,
    required this.phase1Complete,
    required this.phase2Complete,
    this.dbId,
  });

  Household copyWith({
    String? id,
    String? headName,
    int? memberCount,
    String? address,
    bool? phase1Complete,
    bool? phase2Complete,
    String? dbId,
  }) {
    return Household(
      id: id ?? this.id,
      headName: headName ?? this.headName,
      memberCount: memberCount ?? this.memberCount,
      address: address ?? this.address,
      phase1Complete: phase1Complete ?? this.phase1Complete,
      phase2Complete: phase2Complete ?? this.phase2Complete,
      dbId: dbId ?? this.dbId,
    );
  }
}

class DistrictProgress {
  final String district;
  final String state;
  final int tracked;
  final int total;
  final double progress;
  final String lastUpdated;

  const DistrictProgress({
    required this.district,
    required this.state,
    required this.tracked,
    required this.total,
    required this.progress,
    required this.lastUpdated,
  });
}
