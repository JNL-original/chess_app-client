// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionToken)
final sessionTokenProvider = SessionTokenProvider._();

final class SessionTokenProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  SessionTokenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionTokenProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionTokenHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return sessionToken(ref);
  }
}

String _$sessionTokenHash() => r'7008d5f965892553aada6681ebe030f60b6661ac';

@ProviderFor(webSocket)
final webSocketProvider = WebSocketFamily._();

final class WebSocketProvider
    extends
        $FunctionalProvider<
          Raw<WebSocketChannel>,
          Raw<WebSocketChannel>,
          Raw<WebSocketChannel>
        >
    with $Provider<Raw<WebSocketChannel>> {
  WebSocketProvider._({
    required WebSocketFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'webSocketProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$webSocketHash();

  @override
  String toString() {
    return r'webSocketProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Raw<WebSocketChannel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<WebSocketChannel> create(Ref ref) {
    final argument = this.argument as String;
    return webSocket(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<WebSocketChannel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<WebSocketChannel>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WebSocketProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$webSocketHash() => r'3ede350a4f46785eabcd610f9076e27df52e3a1a';

final class WebSocketFamily extends $Family
    with $FunctionalFamilyOverride<Raw<WebSocketChannel>, String> {
  WebSocketFamily._()
    : super(
        retry: null,
        name: r'webSocketProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WebSocketProvider call(String roomId) =>
      WebSocketProvider._(argument: roomId, from: this);

  @override
  String toString() => r'webSocketProvider';
}

@ProviderFor(OfflineConfigControl)
final offlineConfigControlProvider = OfflineConfigControlProvider._();

final class OfflineConfigControlProvider
    extends $NotifierProvider<OfflineConfigControl, OfflineConfig> {
  OfflineConfigControlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineConfigControlProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineConfigControlHash();

  @$internal
  @override
  OfflineConfigControl create() => OfflineConfigControl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfflineConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfflineConfig>(value),
    );
  }
}

String _$offlineConfigControlHash() =>
    r'4175b77ef5d0a41ea536103dcdbebae56eeb5675';

abstract class _$OfflineConfigControl extends $Notifier<OfflineConfig> {
  OfflineConfig build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OfflineConfig, OfflineConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OfflineConfig, OfflineConfig>,
              OfflineConfig,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
