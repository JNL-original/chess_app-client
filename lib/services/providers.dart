import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../configs/config.dart';
import '../models/game.dart';
import 'offline_controller.dart';
import 'online_controller.dart';

part 'providers.g.dart';

// Провайдер для токена сессии
@riverpod
Future<String> sessionToken(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('user_session_token');

  if (token == null) {
    token = const Uuid().v4();
    await prefs.setString('user_session_token', token);
  }

  return token;
}

@riverpod
Future<WebSocketChannel> webSocket(Ref ref, String roomId) async {
  final token = await ref.watch(sessionTokenProvider.future);
  final uri = Uri.parse('wss://chess-server.jnl-x.run/$roomId?token=$token');

  final channel = WebSocketChannel.connect(uri);

  try {
    await channel.ready;
    print("Соединение установлено");
  } catch (e) {
    print("Ошибка при первом подключении: $e.");
    _scheduleRetry(ref, roomId);
    rethrow;
  }

  ref.onDispose(() {
    channel.sink.close(1000);
  });

  channel.sink.done.then((_) {
    if (!ref.mounted) return;

    final closeCode = channel.closeCode;
    print("Socket closed with code: $closeCode");

    if (closeCode != 1000 && closeCode != 1001) {
      _scheduleRetry(ref, roomId);
    }
  });

  return channel;
}

void _scheduleRetry(Ref ref, String roomId) {
  Future.delayed(const Duration(seconds: 3), () {
    if (ref.mounted && ref.exists(webSocketProvider(roomId))) {
      ref.invalidateSelf();
    }
  });
}


@riverpod
class OfflineConfigControl extends _$OfflineConfigControl{
  @override
  OfflineConfig build() => OfflineConfig();
  void updateConfig(OfflineConfig config) => state = config;
}





