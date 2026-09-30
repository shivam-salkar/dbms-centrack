class Household {
  final String id;
  final String headName;
  final int memberCount;
  final String address;
  final bool phase1Complete;
  final bool phase2Complete;

  const Household({
    required this.id,
    required this.headName,
    required this.memberCount,
    required this.address,
    required this.phase1Complete,
    required this.phase2Complete,
  });
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
