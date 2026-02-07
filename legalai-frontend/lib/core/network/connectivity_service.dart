import 'connectivity_service_stub.dart'
    if (dart.library.html) 'connectivity_service_web.dart'
    if (dart.library.io) 'connectivity_service_io.dart';

Future<bool> isOnline() {
  return isOnlineImpl();
}
