import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../configs/config.dart';
import '../services/providers.dart';

class HomeScreen extends ConsumerWidget{
  const HomeScreen({super.key});
  void _showOnlineDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _OnlineDialogContent(ref: ref),
    );
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryFixed,
      title: Text("Шахматы на 4-х", style: Theme.of(context).textTheme.displayLarge,),
      ),
      body: LayoutBuilder(builder: (context, constraints){
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 300, minHeight: 200, maxWidth: max(300, constraints.maxWidth/3), maxHeight: max(200, constraints.maxHeight/3)),
            child: SizedBox.expand(
              child: Column(
                spacing: max(30, constraints.maxHeight/15),
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go("/offline"),
                      child: Text("Offline")
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                        onPressed: () => _showOnlineDialog(context, ref),
                        child: Text("Online")
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

class _OnlineDialogContent extends StatefulWidget {
  final WidgetRef ref;
  const _OnlineDialogContent({required this.ref});

  @override
  State<_OnlineDialogContent> createState() => _OnlineDialogContentState();
}

class _OnlineDialogContentState extends State<_OnlineDialogContent> {
  bool isEnteringCode = false;
  final TextEditingController _codeController = TextEditingController();
  bool get isCodeValid => _codeController.text.trim().length == 6;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      setState(() {});
    });
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 300,
          minHeight: 250,
          maxWidth: 400,
          maxHeight: 300,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isEnteringCode ? _buildCodeInput() : _buildSelectionMenu(),
        ),
      ),
    );
  }

  Widget _buildSelectionMenu() {
    return Column(
      key: const ValueKey(1),
      spacing: 20,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => isEnteringCode = true),
            child: const Text("Войти по коду"),
          ),
        ),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              final config = OnlineConfig();
              final subscription = widget.ref.listenManual(
                webSocketProvider('new'),
                    (previous, next) {
                  next.whenData((channel) {
                    channel.stream.listen((message) {
                      final data = jsonDecode(message);
                      if (data['type'] == 'new_room') {
                        final String newRoomId = data['roomId'];
                        if (context.mounted) Navigator.pop(context);
                        context.go('/online/$newRoomId');
                      }
                    });
                    channel.sink.add(jsonEncode({
                      'type': 'create',
                      'config': config.toMap(),
                    }));
                  });
                },
                fireImmediately: true,
              );
            },
            child: const Text("Создать игру"),
          ),
        ),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Column(
      key: const ValueKey(2),
      spacing: 20,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              splashFactory: NoSplash.splashFactory,
            ),
            child: TextField(
              controller: _codeController,
              maxLength: 6,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: const InputDecoration(
                hintText: "Поле для ввода",
                counterText: "",
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),

        Expanded(
          child: ElevatedButton(
            onPressed: isCodeValid ? _joinByCode : null,
            child: const Text("Войти"),
          ),
        ),

        // 3. Блок возврата
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() {
              isEnteringCode = false;
              _codeController.clear();
            }),
            child: const Text("Назад"),
          ),
        ),
      ],
    );
  }

  void _joinByCode() {
    final code = _codeController.text.trim().toUpperCase();
    Navigator.pop(context);
    context.go('/online/$code');
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

}