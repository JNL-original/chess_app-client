// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OfflineGame)
final offlineGameProvider = OfflineGameProvider._();

final class OfflineGameProvider
    extends $NotifierProvider<OfflineGame, GameState> {
  OfflineGameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineGameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineGameHash();

  @$internal
  @override
  OfflineGame create() => OfflineGame();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameState>(value),
    );
  }
}

String _$offlineGameHash() => r'f098a60b38fdf45cfad9422127f98e25657e88f4';

abstract class _$OfflineGame extends $Notifier<GameState> {
  GameState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GameState, GameState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GameState, GameState>,
              GameState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
