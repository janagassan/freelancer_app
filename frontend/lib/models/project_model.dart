// models/project_model.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'user_model.dart';

class Project {
  int? id;
  String? title;
  String? description;
  double? budget;
  int? duration;
  String? category;
  List<String>? skills;
  String? status;
  int? contractId;
  String? contractStatus;
  String? escrowStatus;
  int? userId;
  int? views;
  int? proposalsCount;
  DateTime? createdAt;
  DateTime? updatedAt;
  User? client;
  List<dynamic>? attachments;
  int? matchScore;
  bool? hasApplied;

  Project({
    this.id,
    this.title,
    this.description,
    this.budget,
    this.duration,
    this.category,
    this.skills,
    this.status,
    this.contractId,
    this.contractStatus,
    this.escrowStatus,
    this.userId,
    this.views,
    this.proposalsCount,
    this.createdAt,
    this.updatedAt,
    this.client,
    this.attachments,
    this.matchScore,
    this.hasApplied,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    print('📦 Project.fromJson - Keys: ${json.keys}');
    print('📦 Client data: ${json['client'] ?? json['User']}');

    List<String> skillsList = [];
    if (json['skills'] != null) {
      if (json['skills'] is List) {
        skillsList = List<String>.from(json['skills']);
      } else if (json['skills'] is String) {
        try {
          final decoded = jsonDecode(json['skills']);
          if (decoded is List) {
            skillsList = List<String>.from(decoded);
          }
        } catch (e) {
          print('Error parsing skills: $e');
        }
      }
    }

    User? client;
    if (json['client'] != null) {
      try {
        client = User.fromJson(json['client']);
        print('✅ Client parsed: ID=${client?.id}, Name=${client?.name}');
      } catch (e) {
        print('❌ Error parsing client: $e');
      }
    } else if (json['User'] != null) {
      try {
        client = User.fromJson(json['User']);
        print(
          '✅ Client parsed from User: ID=${client?.id}, Name=${client?.name}',
        );
      } catch (e) {
        print('❌ Error parsing User: $e');
      }
    } else {
      print('⚠️ No client data in project');
    }

    return Project(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      budget: json['budget']?.toDouble(),
      duration: json['duration'],
      category: json['category'],
      skills: skillsList,
      status: json['status'],
      contractId: json['contractId'] is int
          ? json['contractId']
          : int.tryParse(json['contractId']?.toString() ?? ''),
      contractStatus: json['contractStatus']?.toString(),
      escrowStatus: json['escrowStatus']?.toString(),
      userId: json['UserId'] ?? json['user_id'],
      views: json['views'],
      proposalsCount: json['proposalsCount'] ?? json['proposals_count'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      client: client,
      attachments: json['attachments'] != null
          ? (json['attachments'] is List ? json['attachments'] : [])
          : [],
      matchScore: json['matchScore'],
      hasApplied: json['hasApplied'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'budget': budget,
      'duration': duration,
      'category': category,
      'skills': skills,
      'status': status,
      'UserId': userId,
      'User': client?.toJson(),
    };
  }

  double get completionPercentage {
    if (status == 'completed') return 1.0;
    if (status == 'in_progress') return 0.5;
    if (status == 'open') return 0.0;
    return 0.0;
  }

  Color get statusColor {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color get matchScoreColor {
    if (matchScore == null) return Colors.grey;
    if (matchScore! >= 80) return Colors.green;
    if (matchScore! >= 60) return Colors.orange;
    return Colors.blue;
  }

  String get statusText {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status ?? 'Unknown';
    }
  }

  Project copyWith({
    int? id,
    String? title,
    String? name,
    String? description,
    double? budget,
    int? duration,
    String? status,
    User? client,
    List<String>? skills,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      client: client ?? this.client,
      skills: skills ?? this.skills,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
