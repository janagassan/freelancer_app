// lib/models/message_model.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:freelancer_platform/models/reply_model.dart';
import 'package:freelancer_platform/services/socket_service.dart';

class Message {
  final int id;
  final int chatId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String type;
  final String? mediaUrl;
  final DateTime createdAt;
  final List<int> readBy;
  final bool isReadByMe;
  final int? replyToId;
  final ReplyPreview? replyTo;
  final String? reaction;
  final String? fileName;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? editedAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.createdAt,
    required this.readBy,
    required this.isReadByMe,
    this.replyToId,
    this.replyTo,
    this.reaction,
    this.fileName,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    print('📥 Message.fromJson: ${json.keys}');

    ReplyPreview? replyTo;
    if (json['reply_to'] != null) {
      try {
        final replyData = json['reply_to'];
        if (replyData is Map && replyData.isNotEmpty) {
          replyTo = ReplyPreview.fromJson(replyData.cast<String, dynamic>());
          print('✅ Reply preview parsed: ${replyTo?.content}');
        }
      } catch (e) {
        print('Error parsing replyTo: $e');
      }
    }

    String getSenderName() {
      if (json['sender_name'] != null &&
          json['sender_name'].toString().isNotEmpty) {
        return json['sender_name'].toString();
      }

      if (json['sender'] != null && json['sender']['name'] != null) {
        return json['sender']['name'].toString();
      }

      if (json['user'] != null && json['user']['name'] != null) {
        return json['user']['name'].toString();
      }

      return 'User';
    }

    String? getSenderAvatar() {
      if (json['sender_avatar'] != null &&
          json['sender_avatar'].toString().isNotEmpty) {
        return json['sender_avatar'].toString();
      }
      if (json['sender'] != null && json['sender']['avatar'] != null) {
        return json['sender']['avatar'].toString();
      }
      if (json['user'] != null && json['user']['avatar'] != null) {
        return json['user']['avatar'].toString();
      }
      return null;
    }

    List<int> getReadBy() {
      if (json['read_by'] != null) {
        if (json['read_by'] is List) {
          return (json['read_by'] as List)
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((id) => id > 0)
              .toList();
        }
      }
      return [];
    }

    final message = Message(
      id: int.tryParse(json['id'].toString()) ?? 0,
      chatId: int.tryParse(json['chat_id'].toString()) ?? 0,
      senderId: int.tryParse(json['sender_id'].toString()) ?? 0,
      senderName: getSenderName(),
      senderAvatar: getSenderAvatar(),
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      mediaUrl: json['media_url']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      readBy: getReadBy(),
      isReadByMe: json['is_read_by_me'] ?? false,
      replyToId: json['reply_to_id'] != null
          ? int.tryParse(json['reply_to_id'].toString())
          : null,
      replyTo: replyTo,
      reaction: json['reaction']?.toString(),
      fileName: json['file_name']?.toString(),
      isDeleted: json['is_deleted'] ?? false,
      isEdited: json['is_edited'] ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.tryParse(json['edited_at'].toString())
          : null,
    );

    print(
      '📥 Parsed message: id=${message.id}, senderId=${message.senderId}, senderName=${message.senderName}',
    );

    return message;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'type': type,
      'media_url': mediaUrl,
      'createdAt': createdAt.toIso8601String(),
      'read_by': readBy,
      'is_read_by_me': isReadByMe,
      'reply_to_id': replyToId,
      'reply_to': replyTo?.toJson(),
      'reaction': reaction,
      'file_name': fileName,
      'is_deleted': isDeleted,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
    };
  }

  Message copyWith({
    int? id,
    int? chatId,
    int? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    String? type,
    String? mediaUrl,
    DateTime? createdAt,
    List<int>? readBy,
    bool? isReadByMe,
    int? replyToId,
    ReplyPreview? replyTo,
    String? reaction,
    String? fileName,
    bool? isDeleted,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
      isReadByMe: isReadByMe ?? this.isReadByMe,
      replyToId: replyToId ?? this.replyToId,
      replyTo: replyTo ?? this.replyTo,
      reaction: reaction ?? this.reaction,
      fileName: fileName ?? this.fileName,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  String get displayContent {
    if (isDeleted) return 'This message was deleted';
    if (type == 'image') return '📷 Image';
    if (type == 'file') return '📎 ${fileName ?? 'File'}';
    return content;
  }

  bool get isReplyable => !isDeleted && type != 'image' && type != 'file';
  bool get isEditable => !isDeleted && type == 'text';

  String get editedTimeString {
    if (!isEdited || editedAt == null) return '';
    return ' (edited)';
  }
}

List<Message> parseMessages(List<dynamic> jsonList) {
  return jsonList.map((json) => Message.fromJson(json)).toList();
}

extension MessageUtils on Message {
  bool get isSentByMe => senderId == SocketService.instance.getCurrentUserId();

  bool get isImage => type == 'image';

  bool get isFile => type == 'file';

  bool get isText => type == 'text';

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get readStatusIcon {
    if (readBy.length > 1) return '✅✅';
    if (readBy.isNotEmpty) return '✅';
    return '✓';
  }

  Color getReadStatusColor(bool isDark) {
    if (readBy.length > 1) return Colors.green;
    if (readBy.isNotEmpty) return Colors.blue;
    return isDark ? Colors.grey : Colors.grey.shade400;
  }
}
