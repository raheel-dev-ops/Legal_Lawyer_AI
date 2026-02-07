import 'dart:html' as html;

Future<bool> isOnlineImpl() async {
  return html.window.navigator.onLine ?? true;
}