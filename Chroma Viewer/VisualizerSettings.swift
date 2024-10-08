//
//  VisualizerSettings.swift
//  Chroma Viewer
//
//  Created by Tyler Reckart on 10/4/24.
//

import Foundation
import Combine

enum ShapeMode: Int {
    case kaleidoscope = 0
    case rectangleWarp
    case hexagonWarp
}

class VisualizerSettings: ObservableObject {
    @Published var brightnessMultiplier: Float = 1.2
    @Published var colorShiftSpeed: Float = 0.2
    @Published var timeIncrement: Float = 0.001
    @Published var colorMixFactor: Float = 0.5 // Control how colors are mixed
    @Published var baseHueOffset: Float = 0.1 // Control the color offset for harmonious color schemes

    // Individual color components for controlling the visual appearance
    @Published var redComponent: Float = 1.0
    @Published var greenComponent: Float = 1.0
    @Published var blueComponent: Float = 1.0

    // Amplitude and pitch to control brightness and color dynamics
    @Published var amplitude: Float = 0.0
    @Published var pitch: Float = 0.0

    // Sensitivity for amplitude and pitch
    @Published var amplitudeSensitivity: Float = 1.0
    @Published var pitchSensitivity: Float = 1.0

    // Animation time to control visual effect evolution
    @Published var time: Float = 0.0

    // Control the shape of the gradient animation
    @Published var animationShapeFactor: Float = 1.0
    
    // Distortion controls
    @Published var distortionMode: Bool = false
    @Published var distortionRatio: Float = 0.5
    @Published var distortionShape: Float = 1.0
    @Published var distortionFrequencyRelation: Float = 0.5
    @Published var chaosFactor: Float = 0.5
    
    // Perlin noise controls
    @Published var perlinMode: Bool = false
    @Published var perlinIntensity: Float = 0.5
    @Published var perlinScale: Float = 1.0
    @Published var perlinFrequency: Float = 1.0
    @Published var perlinBlendMode: BlendMode = .overlay
    
    // Kaleidoscope and Warp controls
    @Published var kaleidoscopeMode: Bool = false
    @Published var kaleidoscopeSegments: Int = 6
    @Published var warpIntensity: Float = 0.5
    @Published var twistIntensity: Float = 0.5
    @Published var shapeMode: ShapeMode = .kaleidoscope
    
    // Glitch controls
    @Published var glitchMode: Bool = false
    @Published var glitchFrequency: Float = 1.0  // Controls the frequency of glitches
    @Published var glitchSize: Float = 0.1       // Controls the size of the glitches

    private var cancellables = Set<AnyCancellable>()

    func subscribeToAudioManager(audioManager: AudioInputManager) {
        audioManager.amplitudePublisher
            .sink { [weak self] newAmplitude in
                self?.amplitude = newAmplitude
            }
            .store(in: &cancellables)

        audioManager.pitchPublisher
            .sink { [weak self] newPitch in
                self?.pitch = newPitch
            }
            .store(in: &cancellables)
    }
}
