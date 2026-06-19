//lib\constants.dart
const String BASE_URL = "https://spoils-defog-nylon.ngrok-free.dev/api";

String apiMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final origin = Uri.parse(BASE_URL).origin;
  if (path.startsWith('/')) return '$origin$path';
  return '$origin/$path';
}
