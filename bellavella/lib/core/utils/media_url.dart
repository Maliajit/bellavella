import 'package:bellavella/core/config/app_config.dart';

String resolveMediaUrl(String? rawValue) {
  final raw = rawValue?.trim() ?? '';
  if (raw.isEmpty) {
    return '';
  }

  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }

  if (raw.startsWith('//')) {
    return 'https:$raw';
  }

  var normalized = raw;
  if (normalized.startsWith('/storage/')) {
    return '${AppConfig.origin}$normalized';
  }
  if (normalized.startsWith('storage/')) {
    return '${AppConfig.origin}/$normalized';
  }
  if (normalized.startsWith('/images/')) {
    return '${AppConfig.origin}$normalized';
  }
  if (normalized.startsWith('images/')) {
    return '${AppConfig.origin}/$normalized';
  }
  if (normalized.startsWith('/')) {
    return '${AppConfig.origin}$normalized';
  }

  return '${AppConfig.origin}/storage/$normalized';
}

String? resolveNullableMediaUrl(String? rawValue) {
  final resolved = resolveMediaUrl(rawValue);
  return resolved.isEmpty ? null : resolved;
}
