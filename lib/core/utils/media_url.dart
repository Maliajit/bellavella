import 'package:bellavella/core/config/app_config.dart';

String resolveMediaUrl(String? rawValue) {
  final raw = rawValue?.trim() ?? '';
  if (raw.isEmpty) {
    return '';
  }

  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return _rewriteLocalAbsoluteUrl(raw);
  }

  if (raw.startsWith('//')) {
    return 'https:$raw';
  }

  var normalized = raw;
  if (normalized.startsWith('/storage/')) {
    return '${AppConfig.mediaOrigin}$normalized';
  }
  if (normalized.startsWith('storage/')) {
    return '${AppConfig.mediaOrigin}/$normalized';
  }
  if (normalized.startsWith('/images/')) {
    return '${AppConfig.mediaOrigin}$normalized';
  }
  if (normalized.startsWith('images/')) {
    return '${AppConfig.mediaOrigin}/$normalized';
  }
  if (normalized.startsWith('/')) {
    return '${AppConfig.mediaOrigin}$normalized';
  }

  return '${AppConfig.mediaOrigin}/storage/$normalized';
}

String? resolveNullableMediaUrl(String? rawValue) {
  final resolved = resolveMediaUrl(rawValue);
  return resolved.isEmpty ? null : resolved;
}

String _rewriteLocalAbsoluteUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) {
    return rawUrl;
  }

  final host = uri.host.toLowerCase();
  final isLocalHost =
      host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '10.0.2.2' ||
      host.startsWith('192.168.');

  if (!isLocalHost) {
    return rawUrl;
  }

  final mediaOrigin = Uri.parse(AppConfig.mediaOrigin);
  return uri
      .replace(
        scheme: mediaOrigin.scheme,
        host: mediaOrigin.host,
        port: mediaOrigin.port,
        path: _mergeMediaPath(mediaOrigin.path, uri.path),
      )
      .toString();
}

String _mergeMediaPath(String basePath, String assetPath) {
  final cleanBase = basePath.endsWith('/')
      ? basePath.substring(0, basePath.length - 1)
      : basePath;
  final cleanAsset = assetPath.startsWith('/') ? assetPath : '/$assetPath';

  if (cleanBase.isEmpty || cleanAsset.startsWith(cleanBase)) {
    return cleanAsset;
  }

  return '$cleanBase$cleanAsset';
}
