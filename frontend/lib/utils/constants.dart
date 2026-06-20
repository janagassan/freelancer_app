//lib\constants.dart
const String BASE_URL = "https://https://freelancer-app-h6os.onrender.com/api";

String apiMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final origin = Uri.parse(BASE_URL).origin;
  if (path.startsWith('/')) return '$origin$path';
  return '$origin/$path';
}
