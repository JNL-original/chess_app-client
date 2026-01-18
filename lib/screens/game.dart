
import 'dart:math';
import 'package:web/web.dart' as web; // Импортируем как 'web'
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:chess_app/models/board.dart';
import 'package:chess_app/models/game.dart';
import 'package:chess_app/services/online_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../models/bishop.dart';
import '../models/chess_piece.dart';
import '../models/knight.dart';
import '../models/queen.dart';
import '../models/rook.dart';
import '../services/offline_controller.dart';
import '../services/providers.dart';

class GameScreen extends ConsumerStatefulWidget{
  const GameScreen({super.key, required this.onlineMode, this.id});
  final bool onlineMode;
  final String? id;//Если онлайн мод, то обязательно id
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = widget.onlineMode ? onlineGameProvider(widget.id!) : offlineGameProvider;
    if(ref.read(provider).status == GameStatus.draw
        || ref.read(provider).status == GameStatus.over){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEndForm(context, ref.read(provider));
      });
    }
    if(ref.read(provider).status == GameStatus.waitingForPromotion
        && (ref.read(provider).myPlayerIndex == null || ref.read(provider).myPlayerIndex == ref.read(provider).currentPlayer)){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPromotionForm(context, ref.read(provider));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProvider = widget.onlineMode ? onlineGameProvider(widget.id!) : offlineGameProvider;


    ref.listen(currentProvider.select((s) => s.status), (prev, next) {
      if (next == GameStatus.draw || next == GameStatus.over) {
        //todo конфетти
        if (mounted) _showEndForm(context, ref.read(currentProvider));
      }
    });

    ref.listen(currentProvider.select((s) => s.status), (prev, next) {
      int? myPlayerIndex = ref.read(currentProvider).myPlayerIndex;
      if(next == GameStatus.waitingForPromotion
          && (myPlayerIndex == null || myPlayerIndex == ref.read(currentProvider).currentPlayer)){
        if (mounted) _showPromotionForm(context, ref.read(currentProvider));
      }
    });

    final gameStatus = ref.watch(currentProvider.select((s) => s.status));

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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: InfoBar(onlineMode: widget.onlineMode, id: widget.id)
              ),
              CurrentTurn(onlineMode: widget.onlineMode, roomId: widget.onlineMode ? widget.id! : null),
              const SizedBox(height: 10,),
              _buildMainContent(gameStatus)
            ],
          ),
        )
      );
    }

  Widget _buildMainContent(GameStatus status) {
    switch (status) {
      case GameStatus.connecting:
        return const Expanded(child: Center(child: CircularProgressIndicator()));
      case GameStatus.lobby:
        return _buildLobbyView();
      case GameStatus.notExist:
        return Expanded(child: Center(child: Text("Игра не найдена", style: Theme.of(context).textTheme.bodyLarge,),));
      default:
        return _boardView(); // Сама доска
    }
  }

  Widget _boardView(){
    return Expanded(
      child: Center(
        child: InteractiveViewer(
          //boundaryMargin: const EdgeInsets.all(5.0), // Отступ, чтобы не упираться в края
          minScale: 1, // Минимальный зум
          maxScale: 4.0, // Максимальный зум (в 4 раза)
          child: FittedBox(
            fit: BoxFit.contain, // Вписывает доску в экран, сохраняя пропорции
            child: Padding(
              padding: const EdgeInsets.all(10), // Небольшой отступ «внутри» масштабирования
              child: SizedBox(
                // Задаем жесткий базовый размер.
                // FittedBox растянет или сожмет этот квадрат под экран устройства.
                width: 800,
                height: 800,
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: BoardData.boardSize,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: BoardData.totalTiles,
                  itemBuilder: (context, index) {
                    final myPlayerIndex = ref.read(widget.onlineMode ? onlineGameProvider(widget.id!) : offlineGameProvider).myPlayerIndex ?? 0;
                    final rotationSteps = myPlayerIndex == -1 ? 0 : myPlayerIndex;
                    final realIndex = _rotateIndex(index, rotationSteps);
                    return ChessTile(index: realIndex, onlineMode: widget.onlineMode, roomId: widget.onlineMode ? widget.id! : null);
                  },
                ),
              ),
            ),
          ),
        ),
      )
    );
  }

  void _showEndForm(BuildContext context, GameState state){
    String gameStatus = "Ничья!";
    Color gameOverColor = Colors.black;
    if(state.status != GameStatus.draw){
      if(state.myPlayerIndex == null || state.myPlayerIndex == -1) {
        gameStatus = "Игра окончена!";
      }
      else {
        if(!state.isEnemies(state.myPlayerIndex!, state.alive.indexOf(true))){
          gameStatus = "Победа!";
          gameOverColor = Colors.green;
        }
        else{
          gameStatus = "Поражение!";
          gameOverColor = Colors.red;
        }
      }
    }

    List<int> playerVictoryList = [];
    for(int i = 0; i < 4; i ++){
      if(state.alive[i]!) {
        playerVictoryList.add(i);
      }
    }
    if(state.status == GameStatus.over){
      int player = playerVictoryList.first;
      for(int i = 0; i < 4; i ++){
        if(player != i && !state.isEnemies(player, i) && !playerVictoryList.contains(i)) {
          playerVictoryList.add(i);
        }
      }
    }

    String victoryAction = 'Остались в живых:';
    if(state.status == GameStatus.over){
      if(playerVictoryList.length == 1) {
        victoryAction = 'Победил:';
      }
      else {
        victoryAction = 'Победили:';
      }
    }

    List<Text> playerList = [
      Text(
        victoryAction,
        style: Theme.of(context).textTheme.bodyLarge!
      )
    ];
    for(int index in playerVictoryList){
      playerList.add(
        Text(
          state.config.playerNames[index]!,
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
            color: state.config.playerColors[index],
            shadows: [
              Shadow(offset: Offset(-1, -1), color: Colors.black),
              Shadow(offset: Offset(1, -1), color: Colors.black),
              Shadow(offset: Offset(1, 1), color: Colors.black),
              Shadow(offset: Offset(-1, 1), color: Colors.black),
            ],
          )
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: true,//чтобы игрок мог закрыть окно коснувшись области вне ее
      builder: (context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: AlertDialog(
          title: Center(
            child: Text(
              gameStatus,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: gameOverColor
              ),
            ),
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: playerList,
            ),
          ),
          actions: [
          Container(
          width: double.maxFinite, // Чтобы кнопки были на всю ширину если нужно
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                spacing: 25,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Text("Посмотреть поле"),
                    )
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/');
                    },
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Text("Выйти"),
                    )
                  )
                ],
              ),
            )
          )
          ],
          actionsAlignment: MainAxisAlignment.center,
        ),
      )
    );
  }
  void _showPromotionForm(BuildContext context, GameState state){
    final pieces = [
      Queen(owner: state.currentPlayer),
      Rook(owner: state.currentPlayer),
      Bishop(owner: state.currentPlayer),
      Knight(owner: state.currentPlayer),
    ];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: AlertDialog(
          title: Center(child: Text('Выберите фигуру', style: Theme.of(context).textTheme.bodyLarge,)),
          content: SizedBox(
            width: 250,
            height: 250,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: pieces.length,
              itemBuilder: (context, index) =>
                  _promotionTile(context, pieces[index], widget.onlineMode ? onlineGameProvider(widget.id!) : offlineGameProvider),
            ),
          ),
        ),
      )
    );
  }
  Widget _promotionTile(BuildContext context, ChessPiece piece, dynamic currentProvider) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        ref.read(currentProvider.notifier).continueGameAfterPromotion(piece);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              'assets/pieces/${piece.type}.svg',
              colorFilter: ColorFilter.mode(ref.read(currentProvider).config.playerColors[piece.owner]!, BlendMode.srcIn),
              width: 80,
            ),
            SvgPicture.asset(
              'assets/pieces/${piece.type}_details.svg',
              width: 80,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLobbyView() {
    //Это только онлайн режим
    final provider = onlineGameProvider(widget.id!);
    final lobbyController = ref.watch(provider.notifier);
    final names = ref.watch(provider.select((s) => s.config.playerNames));
    final colors = ref.watch(provider.select((s) => s.config.playerColors));
    final alive = ref.watch(provider.select((s) => s.alive));
    final myPlayerIndex = ref.watch(provider.select((s) => s.myPlayerIndex));

    if (_nameController.text.isEmpty && myPlayerIndex != -1 && names[myPlayerIndex] != null) {
      _nameController.text = names[myPlayerIndex]!;
    }

    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentGeometry.topCenter,
        child: SizedBox(
          width: 400,
          child: Column(
            children: [
              SizedBox(height: 30,),
              ListView.builder(
                shrinkWrap: true,
                itemCount: 4,
                itemBuilder: (context, i) => ListTile(
                  leading: CircleAvatar(backgroundColor: colors[i]),
                  horizontalTitleGap: 30,
                  title: Text(alive[i] != null ? names[i]! : "Ожидание...", style: TextStyle(color: alive[i]!=null ? Colors.black : Colors.grey),),
                  trailing: (alive[i] != null && alive[i]!) ? const Icon(Icons.check, color: Colors.green, size: 40,) : const SizedBox(),
                  titleAlignment: ListTileTitleAlignment.center,
                ),
              ),
            const Divider(height: 60),
            // Блок настроек своего профиля
            if (myPlayerIndex != -1) Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10,),
                    Transform.translate(
                      offset: Offset(0, -10),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {if(!alive[myPlayerIndex!]!) _showColorPicker(context, ref, myPlayerIndex, alive, colors);},
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: colors[myPlayerIndex],
                            child: const Icon(Icons.colorize, color: Colors.white),
                          )
                        ),
                      )
                    ),
                  const SizedBox(width: 20),
                    // Ввод имени
                  Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ваше имя',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 12,
                        enabled: !alive[myPlayerIndex!]!,
                        readOnly: alive[myPlayerIndex]!
                      ),
                    ),
                    SizedBox(width: 25,),
                ],
              ),
              SizedBox(height: 30,),
              if(myPlayerIndex != -1) ElevatedButton(
                onPressed: () {
                  final String currentName = _nameController.text.trim();
                  if(alive[myPlayerIndex]!) {
                    lobbyController.cancelReady();
                  }
                  else{
                    lobbyController.iAmReady(name: (currentName.isEmpty) ? names[myPlayerIndex] : currentName);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: alive[myPlayerIndex]! ? Colors.green : Colors.grey.shade400,
                  foregroundColor: Colors.white, // Цвет текста
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    (alive[myPlayerIndex]!) ? 'ОТМЕНА' : 'ГОТОВ',
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 30,),
            ],
          )
          ]
        )
      ))
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, int index, List<bool?> alive, Map<int, Color> playerColors) {
    final List<Color> availableColors = [
      Colors.purple, Colors.pink.shade200, Colors.pink.shade800,
    Colors.red, Colors.deepOrange.shade400, Colors.orange,
      Colors.yellow.shade700, Colors.yellow, Colors.lightGreen.shade400,
    Colors.green, Colors.teal, Colors.cyan, Colors.blue,
      Colors.indigo, Colors.blueGrey, Colors.black,
    ];

    for (int i = 0; i < 4; i++) {
      if (i != index && alive[i] != null) { // Не убираем наш собственный текущий цвет
        availableColors.removeWhere((color) => color.value == playerColors[i]!.value);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Выберите цвет"),
          content: SizedBox(
            width: 240,
            height: 240,
            child: GridView.builder( // GridView удобнее для фиксированных сеток
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: availableColors.length,
              itemBuilder: (context, colorIndex) {
                final color = availableColors[colorIndex];
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(onlineGameProvider(widget.id!).notifier).changeLobbyProperty(color: color);
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(backgroundColor: color),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  int _rotateIndex(int index, int steps) {
    // steps: 0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°
    if (steps % 4 == 0) return index;

    const int size = 14;
    int x = index % size;
    int y = index ~/ size;

    for (int i = 0; i < (steps % 4); i++) {
      int oldX = x;
      x = size - 1 - y;
      y = oldX;
    }

    return y * size + x;
  }
}


class CurrentTurn extends ConsumerWidget{
  const CurrentTurn({super.key, required this.onlineMode, this.roomId});
  final bool onlineMode;
  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProvider = onlineMode ? onlineGameProvider(roomId!) : offlineGameProvider;
    final playerColors = ref.watch(currentProvider.select((state) => state.config.playerColors));
    final playerNames = ref.watch(currentProvider.select((state) => state.config.playerNames));
    final currentPlayer = ref.watch(currentProvider.select((state) => state.currentPlayer));
    final gameStatus = ref.watch(currentProvider.select((state) => state.status));
    return RichText(
      text: TextSpan(
        text: (gameStatus == GameStatus.active || gameStatus == GameStatus.waitingForPromotion) ? 'Ходит: ' :
              (gameStatus == GameStatus.connecting ? 'Подключение...' : (
              gameStatus == GameStatus.lobby ? 'Ждём игроков' : 'Игра окончена')),
        style: Theme.of(context).textTheme.bodyLarge,
        children: [
          if(gameStatus == GameStatus.active || gameStatus == GameStatus.waitingForPromotion) TextSpan(
            text: playerNames[currentPlayer],
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: playerColors[currentPlayer],
              shadows: [
                Shadow(offset: Offset(-1, -1), color: Colors.black),
                Shadow(offset: Offset(1, -1), color: Colors.black),
                Shadow(offset: Offset(1, 1), color: Colors.black),
                Shadow(offset: Offset(-1, 1), color: Colors.black),
              ],
            )
          )
        ],
      ),
    );
  }

}


class ChessTile extends ConsumerWidget {
  const ChessTile({super.key, required this.index, required this.onlineMode, this.roomId});
  final int index;
  final bool onlineMode;
  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProvider = onlineMode ? onlineGameProvider(roomId!) : offlineGameProvider;

    final playerColors = ref.watch(currentProvider.select((state) => state.config.playerColors));

    final piece = ref.watch(currentProvider.select(
      (state) => state.board[index],
    ));
    final isSelected = ref.watch(currentProvider.select(
      (state) => state.selectedIndex == index
    ));
    final isAvailable = ref.watch(currentProvider.select(
      (state) => state.availableMoves.contains(index)
    ));

    return GestureDetector(
      onTap: () => {ref.read((currentProvider as dynamic).notifier).onTileTapped(index)},
      child: Container(
        color: _getTileColor(index: index, isSelected: isSelected, isAvailable: isAvailable, piece: piece),
        child: Center(
          child: piece == null ? null : Stack(
            children: [
              SvgPicture.asset(
                'assets/pieces/${piece.type}.svg',
                colorFilter: ColorFilter.mode(playerColors[piece.owner]!, BlendMode.srcIn),
                width: 60,
              ),
              SvgPicture.asset(
                'assets/pieces/${piece.type}_details.svg',
                placeholderBuilder: (context) => CircularProgressIndicator(),
                width: 60,
              ),
            ],
          )
        ),
      ),
    );
  }

  Color _getTileColor({required int index, required bool isSelected, required bool isAvailable, required ChessPiece? piece}){
    final int row = index ~/ BoardData.boardSize;
    final int col = index % BoardData.boardSize;

    if (isSelected) {
      return Colors.blue.shade400;
    }

    if (isAvailable){
      if(piece == null){
        return Colors.green.shade200;
      }
      else{
        return Colors.red.shade600;
      }
    }

    if(BoardData.corners.contains(index)){
      return Colors.transparent;
    }

    return (row + col)%2==0 ? Colors.brown.shade200 : Colors.brown.shade800;
  }

}

class InfoBar extends StatelessWidget{
  const InfoBar({super.key, required this.onlineMode, this.id});
  final bool onlineMode;
  final String? id;
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    Widget roomId = Text.rich(
      TextSpan(
        text: "Код комнаты: ",
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black),
        children: [
          TextSpan(
            text: id ?? "Ошибка",
            style: const TextStyle(
              fontWeight: FontWeight.bold, // Делаем жирным только эту часть
            ),
          ),
        ],
      ),
    );
    Widget button = ElevatedButton(
      onPressed: () async {
        String url = "";
        if (kIsWeb) {
          url = web.window.location.href;
        } else {
          url = "https://chess.jnl-x.run/online/${id}";
        }
        await Clipboard.setData(ClipboardData(text: url));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ссылка скопирована!")),
          );
        }
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
      child: Text( "Скопировать ссылку",style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),),
    );
    Widget mode = Text(
      onlineMode ? "Online режим" : "Offline режим",
      style: Theme.of(context).textTheme.bodyMedium,);
    if(width > 750 || !onlineMode){
      return SelectionArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             if(onlineMode)Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: roomId
                  ),
                  const SizedBox(width: 20),
                  Flexible(child: button)
                ],
              ),
            const SizedBox(width: 20), // Минимальный зазор между частями
            mode
          ],
        ),
      );
    }
    return FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child:SelectionArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: roomId
                ),
                const SizedBox(width: 20),
                Flexible(child: button)
              ],
            ),
          ),
        )
    );
  }

}