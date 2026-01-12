// Web implementation - uses dart:html
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Get the current URL from the browser (web only)
String? getCurrentUrl() {
  return html.window.location.href;
}

/// Clear the URL query parameters after handling magic link
void clearUrlQueryParams() {
  final uri = Uri.parse(html.window.location.href);
  final cleanUrl = uri.replace(queryParameters: {}).toString();
  html.window.history.replaceState(null, '', cleanUrl);
}
