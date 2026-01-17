import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoomsScreen extends StatelessWidget{
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                            onPressed: () => context.go('/online/12345'),
                            child: Text("Войти по коду")
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                            onPressed: () => context.go('/online/config'),
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