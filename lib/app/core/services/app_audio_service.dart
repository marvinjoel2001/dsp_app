import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AppAudioService {
  static final AppAudioService _instance = AppAudioService._internal();
  factory AppAudioService() => _instance;
  AppAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
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

  /// Sonido de Alerta de Orden Entrante (30s dispatch ringtone)
  Future<void> playIncomingOrderAlert() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/universfield-ringtone-091-496417.mp3'), volume: 1.0);
    } catch (_) {}
  }

  /// Detener sonido de alerta
  Future<void> stopAlertSound() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  /// Sonido al Aceptar la Orden
  Future<void> playOrderAccepted() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/accepted.mp3'), volume: 1.0);
    } catch (_) {}
  }

  /// Sonido de Dinero / Ganancia acreditada al entregar
  Future<void> playEarningsCash() async {
    try {
      await _audioPlayer.stop();
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
