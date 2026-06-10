// lib/models/usage_limits_model.dart
class UsageLimits {
  final int proposalsUsed;
  final int? proposalsLimit;
  final int activeProjectsUsed;
  final int? activeProjectsLimit;
  final int? interviewsUsed;
  final int? interviewsLimit;
  final String? planSlug;
  final String? planName;

  UsageLimits({
    required this.proposalsUsed,
    this.proposalsLimit,
    required this.activeProjectsUsed,
    this.activeProjectsLimit,
    this.interviewsUsed,
    this.interviewsLimit,
    this.planSlug,
    this.planName,
  });

  factory UsageLimits.fromJson(Map<String, dynamic> json) {
    return UsageLimits(
      proposalsUsed: json['proposals_used'] ?? 0,
      proposalsLimit: json['proposals_limit'],
      activeProjectsUsed: json['active_projects_used'] ?? 0,
      activeProjectsLimit: json['active_projects_limit'],
      interviewsUsed: json['interviews_used'],
      interviewsLimit: json['interviews_limit'],
      planSlug: json['plan_slug']?.toString(),
      planName: json['plan_name']?.toString(),
    );
  }

  double get proposalsProgress {
    if (proposalsLimit == null || proposalsLimit == 0) return 0.0;
    final used = proposalsUsed.toDouble();
    final limit = proposalsLimit!.toDouble();
    return (used / limit).clamp(0.0, 1.0);
  }

  double get activeProjectsProgress {
    if (activeProjectsLimit == null || activeProjectsLimit == 0) return 0.0;
    final used = activeProjectsUsed.toDouble();
    final limit = activeProjectsLimit!.toDouble();
    return (used / limit).clamp(0.0, 1.0);
  }

  int get remainingProposals {
    if (proposalsLimit == null) return -1;
    return proposalsLimit! - proposalsUsed;
  }

  int get remainingActiveProjects {
    if (activeProjectsLimit == null) return -1;
    return activeProjectsLimit! - activeProjectsUsed;
  }

  int? get interviewsRemaining {
    if (interviewsUsed == null || interviewsLimit == null) return null;
    return interviewsLimit! - interviewsUsed!;
  }

  bool get canSubmitProposal {
    if (proposalsLimit == null) return true;
    return proposalsUsed < proposalsLimit!;
  }

  bool get canCreateActiveProject {
    if (activeProjectsLimit == null) return true;
    return activeProjectsUsed < activeProjectsLimit!;
  }

  bool get hasInterviewLimit {
    return interviewsLimit != null && interviewsLimit! > 0;
  }

  bool get hasProposalLimit {
    return proposalsLimit != null && proposalsLimit! > 0;
  }

  bool get canScheduleInterview {
    if (interviewsLimit == null) return true;
    final rem = interviewsRemaining;
    if (rem == null) return true;
    return rem > 0;
  }
}