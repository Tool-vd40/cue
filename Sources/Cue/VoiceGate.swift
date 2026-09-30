import AVFoundation

/// Listens to the microphone and answers one question: talking or silent.
///
/// No speech recognition here, on purpose — people paraphrase their notes,
/// matching words against the text is pointless. A gate is enough:
/// talking — text moves, silent — it stops.
final class VoiceGate {
    private let engine = AVAudioEngine()
    private(set) var isSpeaking = false

    /// Room noise floor. Tracked live: an absolute threshold tuned on one
    /// mic in one room is wrong on another laptop.
    private var floorLevel: Float = 0.005
    /// How long to keep "talking" after the sound drops.
    /// Without it the text jerks in the pauses between words.
    private var hangover = 0
    private let hangoverTicks = 25

    /// How many times louder than the floor counts as speech.
    /// The one knob worth turning if the gate fires on the air conditioner
    /// or misses quiet speech.
    var sensitivity: Float = 3.0

    /// Returns false if there's no mic permission or the engine won't start.
    func start() -> Bool {
        guard !engine.isRunning else { return true }
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        guard format.sampleRate > 0 else { return false }

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.consume(buffer)
        }
        engine.prepare()
        do { try engine.start() } catch {
            input.removeTap(onBus: 0)
            return false
        }
        return true
    }

    func stop() {
        guard engine.isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isSpeaking = false
        hangover = 0
    }

    func consume(_ buffer: AVAudioPCMBuffer) {
        guard let ch = buffer.floatChannelData?[0] else { return }
        let n = Int(buffer.frameLength)
        guard n > 0 else { return }

        var sum: Float = 0
        for i in 0..<n { sum += ch[i] * ch[i] }
        let rms = (sum / Float(n)).squareRoot()

        let loud = rms > max(0.004, floorLevel * sensitivity)
        // Only track the floor in silence, otherwise your own voice raises
        // the threshold to itself and the gate closes mid-sentence.
        if !loud { floorLevel += (rms - floorLevel) * 0.02 }

        if loud { hangover = hangoverTicks } else if hangover > 0 { hangover -= 1 }
        isSpeaking = hangover > 0
    }
}
