import 'package:flutter/services.dart';

class ScreenshotService {
  static const MethodChannel _channel =
      MethodChannel('com.kriptonshare/screenshot');
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _channel.invokeMethod('enableSecureView');
      _isInitialized = true;
    } catch (e) {
      _isInitialized = true;
    }
  }

  static Future<void> enableSecureView() async {
    try {
      await _channel.invokeMethod('enableSecureView');
    } catch (e) {
      // Fallback: no hacemos nada si la plataforma no soporta
    }
  }

  static Future<void> disableSecureView() async {
    try {
      await _channel.invokeMethod('disableSecureView');
    } catch (e) {
      // Fallback: no hacemos nada si la plataforma no soporta
    }
  }
}
