import AVFoundation
import Flutter

/// Workout audio that plays along with music from other apps.
///
/// Beeps use the playback category with `.mixWithOthers`, so music keeps
/// playing. While the voice speaks, the session switches to `.duckOthers`
/// (music gets quieter, it is not paused) and is deactivated with
/// `.notifyOthersOnDeactivation` afterwards so the music returns to full volume.
final class AudioCoach: NSObject, FlutterPlugin, AVSpeechSynthesizerDelegate {
  private let synth = AVSpeechSynthesizer()
  private var players: [String: AVAudioPlayer] = [:]
  private var ducking = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "skakanka/audio", binaryMessenger: registrar.messenger())
    let instance = AudioCoach()
    instance.synth.delegate = instance
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "load":
      setMixing()
      for (name, value) in args {
        guard let data = value as? FlutterStandardTypedData,
              let player = try? AVAudioPlayer(data: data.data) else { continue }
        player.prepareToPlay()
        players[name] = player
      }
      result(nil)
    case "play":
      if let name = args["name"] as? String, let player = players[name] {
        activate()
        player.volume = Float(args["volume"] as? Double ?? 0.8)
        player.currentTime = 0
        player.play()
      }
      result(nil)
    case "speak":
      if let text = args["text"] as? String {
        speak(text, volume: Float(args["volume"] as? Double ?? 0.8))
      }
      result(nil)
    case "stopSpeaking":
      synth.stopSpeaking(at: .immediate)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func setMixing() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
    ducking = false
  }

  private func activate() {
    try? AVAudioSession.sharedInstance().setActive(true)
  }

  private func speak(_ text: String, volume: Float) {
    let session = AVAudioSession.sharedInstance()
    if !ducking {
      try? session.setCategory(.playback, mode: .voicePrompt,
                               options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
      ducking = true
    }
    activate()
    if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "pl-PL")
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
    utterance.volume = volume
    synth.speak(utterance)
  }

  private func endDucking() {
    guard ducking, !synth.isSpeaking else { return }
    // Deactivating lets the music come back to full volume. It fails while a
    // beep is still playing, so retry shortly in that case.
    if players.values.contains(where: { $0.isPlaying }) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.endDucking() }
      return
    }
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    setMixing()
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.endDucking() }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.endDucking() }
  }
}
