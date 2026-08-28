import 'dart:async';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AppAudioService {
  static final AppAudioService _instance = AppAudioService._internal();
  factory AppAudioService() => _instance;
  AppAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  Timer? _vibrateTimer;
  bool _isTtsInitialized = false;
  bool isVoiceGuidanceEnabled = true;

  Future<void> init() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _initTts();
    } catch (_) {}
  }

  Future<void> _initTts() async {
    if (_isTtsInitialized) return;
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isTtsInitialized = true;
    } catch (_) {
      try {
        await _tts.setLanguage('es-US');
        _isTtsInitialized = true;
      } catch (_) {}
    }
  }

  /// Sonido de Alerta de Orden Entrante (30s dispatch ringtone) con Vibración Continua
  Future<void> playIncomingOrderAlert() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(
        AssetSource('sounds/universfield-ringtone-091-496417.mp3'),
        volume: 1.0,
      );

      // Vibración de alerta inicial y ciclo recurrente para llamar la atención del conductor
      _vibrateTimer?.cancel();
      HapticFeedback.heavyImpact();
      _vibrateTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
        HapticFeedback.vibrate();
      });
    } catch (_) {}
  }

  /// Detener sonido de alerta y cancelar vibración
  Future<void> stopAlertSound() async {
    try {
      _vibrateTimer?.cancel();
      _vibrateTimer = null;
      await _audioPlayer.stop();
    } catch (_) {}
  }

  /// Sonido al Aceptar la Orden
  Future<void> playOrderAccepted() async {
    try {
      await stopAlertSound();
      HapticFeedback.mediumImpact();
      await _audioPlayer.play(AssetSource('sounds/accepted.mp3'), volume: 1.0);
    } catch (_) {}
  }

  /// Sonido de Dinero / Ganancia acreditada al entregar
  Future<void> playEarningsCash() async {
    try {
      await stopAlertSound();
      HapticFeedback.heavyImpact();
      await _audioPlayer.play(AssetSource('sounds/cash.mp3'), volume: 1.0);
    } catch (_) {}
  }

  /// Voz Turn-by-Turn en Español para Navegación Activa
  Future<void> speakInstruction(String instruction) async {
    if (!isVoiceGuidanceEnabled || instruction.isEmpty) return;
    try {
      if (!_isTtsInitialized) {
        await _initTts();
      }
      await _tts.stop();
      await _tts.speak(instruction);
    } catch (_) {}
  }

  /// Detener cualquier voz activa
  Future<void> stopSpeech() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
