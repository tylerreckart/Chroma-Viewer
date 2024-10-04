//
//  ContentView.swift
//  Chroma Viewer
//
//  Created by Tyler Reckart on 10/3/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settings = VisualizerSettings()
    @StateObject private var audioManager: AudioInputManager = AudioInputManager()
    private var renderer: MetalRenderer
    @State private var selectedVisualizer: VisualizerType = .fluid

    init() {
        let device = MTLCreateSystemDefaultDevice()!
        let settings = VisualizerSettings()
        let manager = AudioInputManager()
        self._settings = StateObject(wrappedValue: settings)
        self._audioManager = StateObject(wrappedValue: manager)
        self.renderer = MetalRenderer(device: device, settings: settings)
        audioManager.settings = settings // Set the reference to VisualizerSettings in AudioInputManager
        settings.subscribeToAudioManager(audioManager: manager)
    }

    var body: some View {
        VStack {
            MetalViewRepresentable(audioManager: audioManager, renderer: renderer)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)

            VStack {
//                Picker("Visualizer", selection: $selectedVisualizer) {
//                    Text("Fluid").tag(VisualizerType.fluid)
//                    Text("Wave").tag(VisualizerType.wave)
//                }
//                .pickerStyle(SegmentedPickerStyle())
//                .padding()
//                .onChange(of: selectedVisualizer) { newValue in
//                    renderer.visualizerType = newValue
//                }
                HStack {
                    Text("Animation Shape Factor")
                    Slider(value: $settings.animationShapeFactor, in: 0.5...3.0, step: 0.1)
                        .padding()
                }
                
                HStack {
                    Text("Amplitude Sensitivity")
                    Slider(value: $settings.amplitudeSensitivity, in: 0.1...5.0)
                        .padding()
                }

                HStack {
                    Text("Pitch Sensitivity")
                    Slider(value: $settings.pitchSensitivity, in: 0.1...5.0)
                        .padding()
                }

                HStack {
                    Text("Brightness Multiplier")
                    Slider(value: $settings.brightnessMultiplier, in: 0.1...5.0)
                        .padding()
                }

                HStack {
                    Text("Color Shift Speed")
                    Slider(value: $settings.colorShiftSpeed, in: 0.01...1.0)
                        .padding()
                }

                HStack {
                    Text("Color Mix Factor")
                    Slider(value: $settings.colorMixFactor, in: 0.0...1.0)
                        .padding()
                }

                HStack {
                    Text("Base Hue Offset")
                    Slider(value: $settings.baseHueOffset, in: 0.0...1.0)
                        .padding()
                }

//                HStack {
//                    Text("Red Component")
//                    Slider(value: $settings.redComponent, in: 0.0...1.0)
//                        .padding()
//                }
//
//                HStack {
//                    Text("Green Component")
//                    Slider(value: $settings.greenComponent, in: 0.0...1.0)
//                        .padding()
//                }
//
//                HStack {
//                    Text("Blue Component")
//                    Slider(value: $settings.blueComponent, in: 0.0...1.0)
//                        .padding()
//                }
            }
            .padding(.horizontal)
        }
    }
}
