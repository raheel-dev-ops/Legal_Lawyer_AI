import 'dart:io';
import '../constants/app_constants.dart';

const _cacheDuration = Duration(seconds: 10);
DateTime? _lastCheck;
bool? _lastStatus;

Future<bool> isOnlineImpl() async {
  final now = DateTime.now();
  if (_lastCheck != null &&
      _lastStatus != null &&
      now.difference(_lastCheck!) < _cacheDuration) {
    return _lastStatus!;
  }

  final baseUrl = AppConstants.apiBaseUrl;
  final host = Uri.tryParse(baseUrl)?.host ?? '';
  if (host.isEmpty) {
    _lastCheck = now;
    _lastStatus = true;
    return true;
  }

  try {
    final result = await InternetAddress.lookup(host)
        .timeout(const Duration(seconds: 3));
    _lastStatus = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    _lastStatus = false;
  }

  _lastCheck = now;
  return _lastStatus!;
}