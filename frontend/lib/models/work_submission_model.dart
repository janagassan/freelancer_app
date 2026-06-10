// ===== frontend/lib/models/work_submission_model.dart =====
import 'dart:ui';

import 'package:flutter/material.dart';

class WorkSubmission {
  final int id;
  final int contractId;
  final int? milestoneIndex;
  final int freelancerId;
  final int clientId;
  final String title;
  final String? description;
  final List<String> files;
  final List<String> links;
  final String status;
  final String? clientFeedback;
  final String? revisionRequestMessage;
  final DateTime? approvedAt;
  final DateTime submittedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkSubmission({
    required this.id,
    required this.contractId,
    this.milestoneIndex,
    required this.freelancerId,
    required this.clientId,
    required this.title,
    this.description,
    required this.files,
    required this.links,
    required this.status,
    this.clientFeedback,
    this.revisionRequestMessage,
    this.approvedAt,
    required this.submittedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkSubmission.fromJson(Map<String, dynamic> json) {
    return WorkSubmission(
      id: json['id'],
      contractId: json['contract_id'],
      milestoneIndex: json['milestone_index'],
      freelancerId: json['freelancer_id'],
      clientId: json['client_id'],
      title: json['title'],
      description: json['description'],
      files: List<String>.from(json['files'] ?? []),
      links: List<String>.from(json['links'] ?? []),
      status: json['status'],
      clientFeedback: json['client_feedback'],
      revisionRequestMessage: json['revision_request_message'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      submittedAt: DateTime.parse(json['submitted_at']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'milestone_index': milestoneIndex,
      'freelancer_id': freelancerId,
      'client_id': clientId,
      'title': title,
      'description': description,
      'files': files,
      'links': links,
      'status': status,
      'submitted_at': submittedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'revision_request_message': revisionRequestMessage,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isRevisionRequested => status == 'revision_requested';

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved ✓';
      case 'rejected':
        return 'Rejected ✗';
      case 'revision_requested':
        return 'Revision Requested';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'revision_requested':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
