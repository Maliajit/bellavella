import 'package:flutter/foundation.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';

void main() {
  debugPrint('Checking dart_pusher_channels API...');

  final options = PusherChannelsOptions.fromHost(
    scheme: 'ws',
    host: '127.0.0.1',
    port: 8081,
    key: 'local-key',
    shouldSupplyMetadataQueries: true,
    metadata: PusherChannelsOptionsMetadata.byDefault(),
  );

  final pusher = PusherChannelsClient.websocket(
    options: options,
    connectionErrorHandler: (exception, trace, refresh) {
      debugPrint('Connection error: $exception');
    },
  );

  debugPrint('PusherChannelsClient initialized: ${pusher.runtimeType}');
}
