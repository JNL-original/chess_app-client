import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:chess_app/configs/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/providers.dart';

class ConfigScreen extends ConsumerWidget{
  const ConfigScreen({super.key, required this.onlineMode});
  final bool onlineMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.onPrimaryFixed,
          title: Text("Шахматы на 4-х", style: Theme.of(context).textTheme.displayLarge,),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                label: const Text(
                    "В МЕНЮ",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
        body: LayoutBuilder(builder: (context, constraints){
          return Center(
            child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 300, minHeight: 100, maxWidth: max(300, constraints.maxWidth/3), maxHeight: max(100, constraints.maxHeight/6)),
                child: SizedBox.expand(
                  child: Column(
                    spacing: max(30, constraints.maxHeight/15),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                            onPressed: () async {
                              if(!onlineMode){
                                context.go("/offline");
                              }
                              else{
                                final OnlineConfig config = OnlineConfig();
                                final channel = await ref.read(webSocketProvider('new').future);
                                late StreamSubscription sub;
                                sub = channel.stream.listen((message) {
                                  final data = jsonDecode(message);
                                  if (data['type'] == 'new_room') {
                                    final String newRoomId = data['roomId'];
                                    sub.cancel();
                                    context.go('/online/$newRoomId');
                                    Future.delayed(Duration(milliseconds: 100), () {
                                      channel.sink.close(1000);
                                    });
                                  }
                                });
                                channel.sink.add(jsonEncode({
                                  'type': 'create',
                                  'config': config.toMap(),
                                }));
                              }
                            },
                            child: Text("Создать игру")
                        ),
                      ),
                    ],
                  ),
                )
            ),
          );
        })
    );
  }



}

