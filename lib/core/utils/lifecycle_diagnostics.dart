import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Opt in with --dart-define=LIFECYCLE_DIAGNOSTICS=true. Never logs user data,
/// auth tokens, request bodies, query strings, or provider values.
abstract final class LifecycleDiagnostics {
  static const enabled =
      !kReleaseMode && bool.fromEnvironment('LIFECYCLE_DIAGNOSTICS');
  static void event(String component, String event) {
    if (enabled) debugPrint('[CBOA.Lifecycle] $component $event');
  }
}

final class LifecycleProviderObserver extends ProviderObserver {
  String _name(ProviderObserverContext context) =>
      '${context.provider.name ?? context.provider.runtimeType}#${identityHashCode(context.provider)}';
  @override
  void didAddProvider(ProviderObserverContext context, Object? value) =>
      LifecycleDiagnostics.event('provider', 'create ${_name(context)}');
  @override
  void didDisposeProvider(ProviderObserverContext context) =>
      LifecycleDiagnostics.event('provider', 'dispose ${_name(context)}');
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    final status = newValue is AsyncValue
        ? (newValue.isLoading
              ? 'loading'
              : newValue.hasError
              ? 'error'
              : 'data')
        : 'updated';
    LifecycleDiagnostics.event('provider', '$status ${_name(context)}');
  }
}

class LifecycleRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      LifecycleDiagnostics.event(
        'route',
        'push ${route.settings.name ?? route.runtimeType}',
      );
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      LifecycleDiagnostics.event(
        'route',
        'pop ${route.settings.name ?? route.runtimeType}',
      );
}

class LifecycleHttpClient extends http.BaseClient {
  LifecycleHttpClient(this._client);
  final http.Client _client;
  int _sequence = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final id = ++_sequence;
    final path = request.url.pathSegments.take(4).join('/');
    final clock = Stopwatch()..start();
    LifecycleDiagnostics.event('request', '$id start ${request.method} $path');
    try {
      final response = await _client.send(request);
      LifecycleDiagnostics.event(
        'request',
        '$id status=${response.statusCode} elapsedMs=${clock.elapsedMilliseconds}',
      );
      return response;
    } catch (_) {
      LifecycleDiagnostics.event(
        'request',
        '$id failed elapsedMs=${clock.elapsedMilliseconds}',
      );
      rethrow;
    }
  }

  @override
  void close() => _client.close();
}
