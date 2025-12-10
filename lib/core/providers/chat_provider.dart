import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

/// Provider de chat con Supabase Realtime
class ChatProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  Conversation? _activeConversation;
  bool _isLoading = false;
  String? _errorMessage;
  int _totalUnreadCount = 0;

  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _conversationsChannel;

  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  Conversation? get activeConversation => _activeConversation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalUnreadCount => _totalUnreadCount;

  /// Cargar lista de conversaciones
  Future<void> loadConversations() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      final response = await SupabaseService.conversations
          .select('''
            *,
            buyer:user_profiles!buyer_id(*),
            seller:user_profiles!seller_id(*),
            product:products(*)
          ''')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('last_message_at', ascending: false);

      _conversations = (response as List)
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();

      _updateTotalUnreadCount();
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Iniciar o obtener conversación existente
  Future<Conversation?> startConversation(Product product) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return null;

      // Verificar si ya existe una conversación
      final existing = await SupabaseService.conversations
          .select('''
            *,
            buyer:user_profiles!buyer_id(*),
            seller:user_profiles!seller_id(*),
            product:products(*)
          ''')
          .eq('buyer_id', userId)
          .eq('product_id', product.id)
          .maybeSingle();

      if (existing != null) {
        return Conversation.fromJson(existing);
      }

      // Crear nueva conversación
      final response = await SupabaseService.conversations
          .insert({
            'buyer_id': userId,
            'seller_id': product.sellerId,
            'product_id': product.id,
          })
          .select('''
            *,
            buyer:user_profiles!buyer_id(*),
            seller:user_profiles!seller_id(*),
            product:products(*)
          ''')
          .single();

      final conversation = Conversation.fromJson(response);
      _conversations.insert(0, conversation);
      notifyListeners();
      return conversation;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  /// Cargar mensajes de una conversación
  Future<void> loadMessages(String conversationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await SupabaseService.messages
          .select('''
            *,
            sender:user_profiles!sender_id(*)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      _messages = (response as List)
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();

      // Marcar como leídos
      await _markMessagesAsRead(conversationId);

      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Enviar mensaje
  Future<bool> sendMessage(String conversationId, String content) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return false;

      final response = await SupabaseService.messages
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'content': content,
          })
          .select('''
            *,
            sender:user_profiles!sender_id(*)
          ''')
          .single();

      final message = Message.fromJson(response);
      _messages.add(message);

      // Actualizar conversación
      await SupabaseService.conversations.update({
        'last_message': content,
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      // Actualizar lista local
      final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (convIndex != -1) {
        _conversations[convIndex] = _conversations[convIndex].copyWith(
          lastMessage: content,
          lastMessageAt: DateTime.now(),
        );
        // Mover al inicio
        final conv = _conversations.removeAt(convIndex);
        _conversations.insert(0, conv);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Suscribirse a mensajes en tiempo real
  void subscribeToMessages(String conversationId) {
    _messagesChannel?.unsubscribe();

    _messagesChannel = SupabaseService.client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) async {
            final newMessage = payload.newRecord;
            if (newMessage['sender_id'] != SupabaseService.currentUserId) {
              // Cargar mensaje con relaciones
              final response = await SupabaseService.messages
                  .select('''
                    *,
                    sender:user_profiles!sender_id(*)
                  ''')
                  .eq('id', newMessage['id'])
                  .single();

              final message = Message.fromJson(response);

              // Evitar duplicados
              if (!_messages.any((m) => m.id == message.id)) {
                _messages.add(message);
                notifyListeners();
              }

              // Marcar como leído
              await _markMessagesAsRead(conversationId);
            }
          },
        )
        .subscribe();
  }

  /// Suscribirse a actualizaciones de conversaciones
  void subscribeToConversations() {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    _conversationsChannel?.unsubscribe();

    _conversationsChannel = SupabaseService.client
        .channel('conversations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            loadConversations();
          },
        )
        .subscribe();
  }

  /// Marcar mensajes como leídos
  Future<void> _markMessagesAsRead(String conversationId) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      await SupabaseService.messages
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      // Resetear contador de no leídos
      await SupabaseService.conversations
          .update({'unread_count': 0})
          .eq('id', conversationId);

      // Actualizar local
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
        _updateTotalUnreadCount();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Actualizar contador total de no leídos
  void _updateTotalUnreadCount() {
    _totalUnreadCount = _conversations.fold(0, (sum, c) => sum + c.unreadCount);
  }

  /// Establecer conversación activa
  void setActiveConversation(Conversation? conversation) {
    _activeConversation = conversation;
    if (conversation != null) {
      loadMessages(conversation.id);
      subscribeToMessages(conversation.id);
    }
    notifyListeners();
  }

  /// Limpiar al cerrar chat
  void clearActiveChat() {
    _activeConversation = null;
    _messages = [];
    _messagesChannel?.unsubscribe();
    notifyListeners();
  }

  /// Limpiar todo (al cerrar sesión)
  void clear() {
    _conversations = [];
    _messages = [];
    _activeConversation = null;
    _totalUnreadCount = 0;
    _messagesChannel?.unsubscribe();
    _conversationsChannel?.unsubscribe();
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _conversationsChannel?.unsubscribe();
    super.dispose();
  }
}

