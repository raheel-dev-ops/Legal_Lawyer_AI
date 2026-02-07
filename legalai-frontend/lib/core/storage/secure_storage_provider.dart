import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_provider.g.dart';

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  return SafeSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
}

class SafeSecureStorage extends FlutterSecureStorage {
  SafeSecureStorage({
    super.aOptions = AndroidOptions.defaultOptions,
    super.iOptions = IOSOptions.defaultOptions,
    super.lOptions = LinuxOptions.defaultOptions,
    super.wOptions = WindowsOptions.defaultOptions,
    super.webOptions = WebOptions.defaultOptions,
    super.mOptions = MacOsOptions.defaultOptions,
  });

  static const String _webBoxName = 'secure_storage';

  Future<Box> _webBox() async {
    if (!Hive.isBoxOpen(_webBoxName)) {
      await Hive.openBox(_webBoxName);
    }
    return Hive.box(_webBoxName);
  }

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (kIsWeb) {
      final box = await _webBox();
      return box.get(key) as String?;
    }
    try {
      return await super.read(
        key: key,
        aOptions: aOptions,
        iOptions: iOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } catch (_) {
      final box = await _webBox();
      return box.get(key) as String?;
    }
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (kIsWeb) {
      final box = await _webBox();
      if (value == null) {
        await box.delete(key);
      } else {
        await box.put(key, value);
      }
      return;
    }
    try {
      await super.write(
        key: key,
        value: value,
        aOptions: aOptions,
        iOptions: iOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } catch (_) {
      final box = await _webBox();
      if (value == null) {
        await box.delete(key);
      } else {
        await box.put(key, value);
      }
    }
  }

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (kIsWeb) {
      final box = await _webBox();
      await box.delete(key);
      return;
    }
    try {
      await super.delete(
        key: key,
        aOptions: aOptions,
        iOptions: iOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } catch (_) {
      final box = await _webBox();
      await box.delete(key);
    }
  }
}
