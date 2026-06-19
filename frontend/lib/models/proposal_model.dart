// lib/models/proposal_model.dart
import 'dart:convert';
import 'project_model.dart';
import 'user_model.dart';
import 'freelancer_profile.dart';

class Proposal {
  final int? id;
  final int? projectId;
  final int? userId;
  final double? price;
  final int? deliveryTime;
  final String? proposalText;
  final String? status;
  final DateTime? createdAt;
  final Project? project;
  final User? freelancer;
  final FreelancerProfile? freelancerProfile;
  final List<Map<String, dynamic>>? milestones;
  final int? contractId;

  Proposal({
    this.id,
    this.projectId,
    this.userId,
    this.price,
    this.deliveryTime,
    this.proposalText,
    this.status,
    this.createdAt,
    this.project,
    this.freelancer,
    this.freelancerProfile,
    this.milestones,
    this.contractId,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    print('📥 Proposal.fromJson received: ${json.keys}');

    List<String> parseSkills(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) {
            return parsed.map((e) => e.toString()).toList();
          }
        } catch (e) {}
        return data.split(',').map((s) => s.trim()).toList();
      }
      return [];
    }

    List<Map<String, dynamic>> parseMilestones(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      if (data is String && data.isNotEmpty) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) {
            return parsed.map((e) => Map<String, dynamic>.from(e)).toList();
          }
        } catch (e) {}
      }
      return [];
    }

    Project? project;

    if (json['project'] != null && json['project'] is Map) {
      try {
        project = Project.fromJson(Map<String, dynamic>.from(json['project']));
        print('✅ Project loaded from project field: ${project?.title}');
      } catch (e) {
        print('⚠️ Error parsing project from project field: $e');
      }
    }

    if (project == null && json['Project'] != null && json['Project'] is Map) {
      try {
        project = Project.fromJson(Map<String, dynamic>.from(json['Project']));
        print('✅ Project loaded from Project field: ${project?.title}');
      } catch (e) {
        print('⚠️ Error parsing project from Project field: $e');
      }
    }

    if (project == null) {
      print('⚠️ No project found, creating default project');

      String? projectTitle =
          json['project_title'] ??
          json['ProjectTitle'] ??
          json['title'] ??
          'Unknown Project';

      int? projectId =
          json['projectId'] ?? json['ProjectId'] ?? json['project_id'];

      double? projectBudget = json['budget'] != null
          ? (json['budget'] is double
                ? json['budget']
                : double.tryParse(json['budget'].toString()))
          : null;

      project = Project(
        id: projectId,
        title: projectTitle,
        budget: projectBudget,
        description: json['project_description'] ?? json['description'],
      );
    }

    if (project != null && project.client == null) {
      Map<String, dynamic>? clientData;

      if (json['project'] != null &&
          json['project'] is Map &&
          json['project']['client'] != null) {
        clientData = Map<String, dynamic>.from(json['project']['client']);
      } else if (json['Project'] != null &&
          json['Project'] is Map &&
          json['Project']['client'] != null) {
        clientData = Map<String, dynamic>.from(json['Project']['client']);
      } else if (json['client'] != null && json['client'] is Map) {
        clientData = Map<String, dynamic>.from(json['client']);
      } else if (json['Client'] != null && json['Client'] is Map) {
        clientData = Map<String, dynamic>.from(json['Client']);
      }

      if (clientData != null) {
        try {
          project = project!.copyWith(client: User.fromJson(clientData));
          print('✅ Client loaded: ${project?.client?.name}');
        } catch (e) {
          print('⚠️ Error parsing client: $e');
        }
      }

      if (project?.client == null) {
        String? clientName =
            json['client_name'] ??
            json['ClientName'] ??
            json['user_name'] ??
            'Unknown Client';

        project = project!.copyWith(
          client: User(
            id: json['client_id'] ?? json['ClientId'],
            name: clientName,
            avatar: json['client_avatar'] ?? json['ClientAvatar'],
            email: json['client_email'] ?? json['ClientEmail'],
          ),
        );
      }
    }

    User? freelancer;
    if (json['freelancer'] != null && json['freelancer'] is Map) {
      try {
        freelancer = User.fromJson(
          Map<String, dynamic>.from(json['freelancer']),
        );
        print('✅ Freelancer loaded: ${freelancer?.name}');
      } catch (e) {
        print('⚠️ Error parsing freelancer: $e');
      }
    }

    if (freelancer == null && json['UserId'] != null) {
      freelancer = User(
        id: json['UserId'],
        name: json['user_name'] ?? 'Freelancer',
        avatar: json['user_avatar'],
      );
    }

    FreelancerProfile? freelancerProfile;
    if (json['profile'] != null && json['profile'] is Map) {
      try {
        freelancerProfile = FreelancerProfile.fromJson(
          Map<String, dynamic>.from(json['profile']),
        );
        print('✅ FreelancerProfile loaded');
      } catch (e) {
        print('⚠️ Error parsing freelancer profile: $e');
      }
    }

    if (freelancerProfile == null && json['freelancer_profile'] != null) {
      try {
        freelancerProfile = FreelancerProfile.fromJson(
          Map<String, dynamic>.from(json['freelancer_profile']),
        );
        print('✅ FreelancerProfile loaded from freelancer_profile');
      } catch (e) {
        print('⚠️ Error parsing freelancer profile: $e');
      }
    }

    double? price = _parseDouble(json['price']);
    if (price == 0.0 && json['bid_amount'] != null) {
      price = _parseDouble(json['bid_amount']);
    }
    if (price == 0.0 && project?.budget != null) {
      price = project!.budget;
    }

    int? deliveryTime;
    if (json['delivery_time'] != null) {
      deliveryTime = json['delivery_time'] is int
          ? json['delivery_time']
          : int.tryParse(json['delivery_time'].toString());
    }
    if ((deliveryTime == null || deliveryTime == 0) &&
        json['duration'] != null) {
      deliveryTime = json['duration'] is int
          ? json['duration']
          : int.tryParse(json['duration'].toString());
    }

    return Proposal(
      id: json['id'],
      projectId: json['ProjectId'] ?? json['projectId'] ?? json['project_id'],
      userId: json['UserId'] ?? json['userId'] ?? json['user_id'],
      price: price,
      deliveryTime: deliveryTime ?? 7,
      proposalText:
          json['proposal_text'] ?? json['coverLetter'] ?? json['cover_letter'],
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : (json['created_at'] != null
                ? DateTime.tryParse(json['created_at'])
                : null),
      project: project,
      freelancer: freelancer,
      freelancerProfile: freelancerProfile,
      milestones: parseMilestones(json['milestones']),
      contractId: json['contractId'] ?? json['contract_id'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String getSafeProjectTitle() {
    if (project?.title != null && project!.title!.isNotEmpty) {
      return project!.title!;
    }
    if (project?.title != null && project!.title!.isNotEmpty) {
      return project!.title!;
    }
    return 'Unknown Project';
  }

  String getSafeClientName() {
    if (project?.client?.name != null && project!.client!.name!.isNotEmpty) {
      return project!.client!.name!;
    }
    if (freelancer != null &&
        freelancer!.name != null &&
        freelancer!.name!.isNotEmpty) {
      return freelancer!.name!;
    }
    return 'Unknown Client';
  }

  String? getSafeClientAvatar() {
    if (project?.client?.avatar != null &&
        project!.client!.avatar!.isNotEmpty) {
      return project!.client!.avatar;
    }
    if (freelancer?.avatar != null && freelancer!.avatar!.isNotEmpty) {
      return freelancer!.avatar;
    }
    return null;
  }

  double getSafePrice() {
    if (price != null && price! > 0) return price!;
    if (project?.budget != null && project!.budget! > 0)
      return project!.budget!;
    return 0.0;
  }

  int getSafeDeliveryTime() {
    if (deliveryTime != null && deliveryTime! > 0) return deliveryTime!;
    if (project?.duration != null && project!.duration! > 0)
      return project!.duration!;
    return 7;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'userId': userId,
      'price': price,
      'deliveryTime': deliveryTime,
      'proposalText': proposalText,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'project': project?.toJson(),
      'freelancer': freelancer?.toJson(),
      'contractId': contractId,
    };
  }

  void debugPrint() {
    print('📄 Proposal Details:');
    print('  - ID: $id');
    print('  - Status: $status');
    print('  - Price: \$${getSafePrice()}');
    print('  - Delivery: ${getSafeDeliveryTime()} days');
    print('  - Project: ${getSafeProjectTitle()}');
    print('  - Client: ${getSafeClientName()}');
    print('  - Created: $createdAt');
  }
}

extension ProposalListExtension on List<Proposal> {
  List<Proposal> get pending => where((p) => p.status == 'pending').toList();
  List<Proposal> get accepted => where((p) => p.status == 'accepted').toList();
  List<Proposal> get rejected => where((p) => p.status == 'rejected').toList();
  List<Proposal> get active => where((p) => p.status == 'active').toList();

  Map<String, List<Proposal>> groupByStatus() {
    return {
      'pending': pending,
      'accepted': accepted,
      'rejected': rejected,
      'active': active,
    };
  }
}
