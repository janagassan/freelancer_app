// lib/services/socket_service.dart - قم بتعديل الكامل

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../utils/token_storage.dart';

class SocketService {
  static SocketService? _instance;
  static SocketService get instance => _instance ??= SocketService._();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  bool _isDisposed = false;

  final _chatsController = StreamController<List<ChatModel>>.broadcast();
  final _newMessageController = StreamController<Message>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _messageDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageEditedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _reactionController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageErrorController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessageDeleted =>
      _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get onMessageEdited =>
      _messageEditedController.stream;
  Stream<List<ChatModel>> get onChatsUpdate => _chatsController.stream;
  Stream<Message> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onReadReceipt =>
      _readReceiptController.stream;
  Stream<bool> get onConnectionChange => _connectionController.stream;
  Stream<Map<String, dynamic>> get onReaction => _reactionController.stream;
  Stream<Map<String, dynamic>> get onMessageError =>
      _messageErrorController.stream;

  SocketService._();

  bool get isConnected => _isConnected;

  int? getCurrentUserId() {
    if (_currentUserId != null) {
      final userId = int.tryParse(_currentUserId!);
      print('📱 getCurrentUserId() returning: $userId');
      return userId;
    }
    print('📱 getCurrentUserId() returning: null');
    return null;
  }

  String? getCurrentUserIdString() {
    print('📱 getCurrentUserIdString() returning: $_currentUserId');
    return _currentUserId;
  }

  Future<void> init() async {
    print('🔌 ========== SOCKET INIT START ==========');

    final token = await TokenStorage.getToken();
    final userIdStr = await TokenStorage.getUserId();
    final user = await TokenStorage.getUser();

    print('🔌 Token exists: ${token != null}');
    print('🔌 UserId from storage: $userIdStr');
    print('🔌 Stored user: ${user?['id']} - ${user?['name']}');

    if (token == null || userIdStr == null) {
      print('❌ Cannot connect: No token or user ID');
      print('🔌 This might be normal if user is not logged in yet');
      _connectionController.add(false);
      return;
    }

    _currentUserId = userIdStr;
    print('🔌 Set _currentUserId to: $_currentUserId');

    try {
      final String socketUrl = kIsWeb
          ? 'https://freelancer-app-h6os.onrender.com'
          : 'https://freelancer-app-h6os.onrender.com';
      print('🔌 Connecting to socket at: $socketUrl');

      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
      }

      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'auth': {'userId': userIdStr, 'token': token},
        'extraHeaders': {'Authorization': 'Bearer $token'},
      });

      _setupListeners();
    } catch (e) {
      print('❌ Error creating socket: $e');
      _connectionController.add(false);
    }
  }

  Future<void> reconnect() async {
    print('🔄 Attempting to reconnect...');
    _isConnected = false;
    await init();
  }

  void _setupListeners() {
    _socket!.onConnecting((_) {
      print('🔄 Socket is connecting...');
    });

    _socket!.onConnectTimeout((_) {
      print('⏰ Socket connection timeout!');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onConnect((_) {
      if (_isDisposed) return;
      _isConnected = true;
      print('✅✅✅✅✅ Socket CONNECTED for user: $_currentUserId ✅✅✅✅✅');
      _connectionController.add(true);
      _socket!.emit('ping', {'timestamp': DateTime.now().toIso8601String()});
    });

    _socket!.onConnectError((data) {
      if (_isDisposed) return;
      print('⚠️ Socket connection error: $data');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onDisconnect((_) {
      if (_isDisposed) return;
      print('❌ Socket disconnected for user: $_currentUserId');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.on('pong', (data) {
      if (_isDisposed) return;
      print('🏓 Socket pong received');
    });

    _socket!.on('chats_list', (data) {
      if (_isDisposed) return;
      print(
        '📨 Received chats_list for user $_currentUserId: ${data?.length ?? 0} chats',
      );
      if (data != null) {
        final chats = (data as List)
            .map((json) => ChatModel.fromJson(json))
            .toList();
        _chatsController.add(chats);
      }
    });

    _socket!.on('new_message', (data) {
      if (_isDisposed) return;
      print('💬 New message received for user $_currentUserId');
      if (data != null) {
        final message = Message.fromJson(data);
        print(
          '💬 Message sender: ${message.senderId}, Current user: $_currentUserId',
        );
        _newMessageController.add(message);
      }
    });

    _socket!.on('user_typing', (data) {
      if (_isDisposed) return;
      print('✍️ Typing event: $data');
      if (data != null) {
        _typingController.add(data);
      }
    });

    _socket!.on('messages_read', (data) {
      if (_isDisposed) return;
      print('✅ Messages read: $data');
      if (data != null) {
        _readReceiptController.add(data);
      }
    });

    _socket!.on('message_deleted', (data) {
      if (_isDisposed) return;
      print('🗑️ Message deleted: $data');
      if (data != null) {
        _messageDeletedController.add(data);
      }
    });

    _socket!.on('message_edited', (data) {
      if (_isDisposed) return;
      print('✏️ Message edited: $data');
      if (data != null) {
        _messageEditedController.add(data);
      }
    });

    _socket!.on('message_reaction', (data) {
      if (_isDisposed) return;
      print('😊 Message reaction: $data');
      if (data != null) {
        _reactionController.add(data);
      }
    });
    _socket!.on('connect', (_) {
      print('🎯 Socket connect event fired');
    });

    _socket!.on('connect_error', (error) {
      print('❌ Socket connect_error: $error');
    });

    _socket!.on('error', (error) {
      print('❌ Socket error: $error');
    });

    _socket!.on('message_error', (data) {
      if (_isDisposed) return;
      print('❌ Socket message_error: $data');
      if (data != null) {
        _messageErrorController.add(data);
      }
    });

    _socket!.on('new_message_notification', (data) {
      if (_isDisposed) return;
      print('🔔 New message notification: $data');
      final senderName = data?['sender']?['name'] ?? 'Someone';
      final messageContent = data?['message']?['content'] ?? '';
      Fluttertoast.showToast(
        msg: '$senderName: $messageContent',
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        timeInSecForIosWeb: 3,
      );
    });
  }

  void joinChat(int chatId) {
    if (_isConnected && _socket != null && chatId != null) {
      print('📢 User $_currentUserId joining chat: $chatId');
      _socket!.emit('join_chat', chatId);
    } else {
      print(
        '⚠️ Cannot join chat: connected=$_isConnected, socket=${_socket != null}',
      );
    }
  }

  void leaveChat(int chatId) {
    if (_isConnected && _socket != null && chatId != null) {
      print('👋 User $_currentUserId leaving chat: $chatId');
      _socket!.emit('leave_chat', chatId);
    }
  }

  Future<void> updateUserData(Map<String, dynamic> user) async {
    if (_isConnected && _socket != null) {
      print('🔄 Updating socket user data: ${user['name']}');
      _socket!.emit('update_user', {
        'name': user['name'],
        'avatar': user['avatar'],
      });
    }
  }

  Future<bool> ensureConnection({int timeoutSeconds = 5}) async {
    if (_isConnected) return true;

    await reconnect();

    final completer = Completer<bool>();
    late StreamSubscription sub;

    sub = _connectionController.stream.listen((connected) {
      if (!completer.isCompleted) {
        completer.complete(connected);
        sub.cancel();
      }
    });

    return completer.future.timeout(
      Duration(seconds: timeoutSeconds),
      onTimeout: () {
        sub.cancel();
        return false;
      },
    );
  }

  void sendTyping(int chatId, bool isTyping) {
    if (_isConnected && _socket != null) {
      print(
        '✍️ User $_currentUserId sending typing event for chat $chatId: $isTyping',
      );
      _socket!.emit('typing', {'chatId': chatId, 'isTyping': isTyping});
    }
  }

  void markAsRead(int chatId) {
    if (_isConnected && _socket != null) {
      print('✅ User $_currentUserId marking chat $chatId as read');
      _socket!.emit('mark_read', {'chatId': chatId});
    }
  }

  void sendMessage({
    required int chatId,
    required String content,
    String type = 'text',
    String? mediaUrl,
    String? fileName,
    int? replyTo,
  }) async {
    if (!_isConnected) {
      print('⚠️ Cannot send message: Not connected (user: $_currentUserId)');
      Fluttertoast.showToast(
        msg: 'Not connected to chat server',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (_socket == null) {
      print('⚠️ Cannot send message: Socket is null');
      return;
    }

    final user = await TokenStorage.getUser();
    final senderName = user?['name'] ?? 'User';

    print(
      '📤 User $_currentUserId ($senderName) sending message to chat $chatId: $content',
    );
    print('📤 Reply to: $replyTo');

    final messageData = {
      'chatId': chatId,
      'content': content,
      'type': type,
      'senderName': senderName,
      'senderAvatar': user?['avatar'],
    };

    if (replyTo != null) {
      messageData['replyToId'] = replyTo;
    }

    if (mediaUrl != null) messageData['mediaUrl'] = mediaUrl;
    if (fileName != null) messageData['fileName'] = fileName;

    _socket!.emit('send_message', messageData);
    print('✅ Message sent by user $_currentUserId');
  }

  void sendReaction(int messageId, String reaction) {
    if (_isConnected && _socket != null) {
      print(
        '😊 User $_currentUserId sending reaction for message $messageId: $reaction',
      );
      _socket!.emit('send_reaction', {
        'messageId': messageId,
        'reaction': reaction,
      });
    }
  }

  void editMessage(int messageId, String content) {
    if (_isConnected && _socket != null) {
      print('✏️ User $_currentUserId editing message $messageId');
      _socket!.emit('edit_message', {
        'messageId': messageId,
        'content': content,
      });
    }
  }

  void deleteMessage(int messageId) {
    if (_isConnected && _socket != null) {
      print('🗑️ User $_currentUserId deleting message $messageId');
      _socket!.emit('delete_message', {'messageId': messageId});
    }
  }

  void loadMoreMessages(int chatId, int offset, {int limit = 20}) {
    if (_isConnected && _socket != null) {
      _socket!.emit('load_more_messages', {
        'chatId': chatId,
        'offset': offset,
        'limit': limit,
      });
    }
  }

  Future<void> logoutAndClear() async {
    print('🚪 User $_currentUserId logging out and clearing socket...');

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _isConnected = false;
    _currentUserId = null;

    await TokenStorage.clearAll();

    print('✅ Logout completed');
  }

  Future<void> loginWithNewUser(
    String token,
    String userId,
    Map<String, dynamic> user,
  ) async {
    print('🔐 Logging in with new user: $userId - ${user['name']}');

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _isConnected = false;

    await TokenStorage.saveToken(token);
    await TokenStorage.saveUserId(int.parse(userId));
    await TokenStorage.saveUser(user);

    await init();
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }
    _isConnected = false;
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _chatsController.close();
    _newMessageController.close();
    _typingController.close();
    _readReceiptController.close();
    _connectionController.close();
  }
}
