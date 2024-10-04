//
//  AudioInputManager.swift
//  Chroma Viewer
//
//  Created by Tyler Reckart on 10/4/24.
//

import Foundation
import AVFoundation
import Accelerate
import Combine

class AudioInputManager: ObservableObject {
    private let audioEngine = AVAudioEngine()
    @Published var amplitude: Float = 0.0
    @Published var pitch: Float = 0.0

    var settings: VisualizerSettings?
    var amplitudePublisher = PassthroughSubject<Float, Never>()
    var pitchPublisher = PassthroughSubject<Float, Never>()

    init() {
        requestMicrophoneAccess()
    }

    func requestMicrophoneAccess() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                self.startAudioCapture()
            } else {
                print("Microphone access denied")
            }
        }
    }

    func startAudioCapture() {
        let inputNode = audioEngine.inputNode

        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.channelCount > 0 else {
            print("Invalid input format. Channel count is zero.")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { (buffer, _) in
            self.processAudio(buffer: buffer)
        }

        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    private func processAudio(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }

        let frameLength = buffer.frameLength
        var rms: Float = 0.0
        vDSP_meamgv(channelData, 1, &rms, vDSP_Length(frameLength))
        
        DispatchQueue.main.async {
            self.amplitude = rms
            self.pitch = abs(rms * 1000)

            // Publish updates instead of updating directly
            self.amplitudePublisher.send(self.amplitude)
            self.pitchPublisher.send(self.pitch)
        }
    }
}
