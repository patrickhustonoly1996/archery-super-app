// Web implementation - uses package:web
import 'package:web/web.dart' as web;

/// Get the current URL from the browser (web only)
String? getCurrentUrl() {
  return web.window.location.href;
}

/// Clear the URL query parameters after handling magic link
void clearUrlQueryParams() {
  final uri = Uri.parse(web.window.location.href);
  final cleanUrl = uri.replace(queryParameters: {}).toString();
  web.window.history.replaceState(null, '', cleanUrl);
}
