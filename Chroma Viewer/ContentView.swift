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
                TabView {
                    // Gradient Controls
                    ScrollView  {
                        Text("Gradient Controls").font(.headline)
                        HStack {
                            Text("Amplitude Sensitivity")
                            Slider(value: $settings.amplitudeSensitivity, in: 1.0...5.0)
                                .padding()
                        }
                        
                        HStack {
                            Text("Pitch Sensitivity")
                            Slider(value: $settings.pitchSensitivity, in: 1.0...5.0)
                                .padding()
                        }

                        HStack {
                            Text("Color Mix Factor")
                            Slider(value: $settings.colorMixFactor, in: 0.0...1.0)
                                .padding()
                        }

                        HStack {
                            Text("Animation Shape Factor")
                            Slider(value: $settings.animationShapeFactor, in: 1.0...5.0, step: 0.1)
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
                            Text("Base Hue Offset")
                            Slider(value: $settings.baseHueOffset, in: 0.0...1.0)
                                .padding()
                        }

                        HStack {
                            Text("Red Component")
                            Slider(value: $settings.redComponent, in: 0.0...1.0)
                                .padding()
                        }

                        HStack {
                            Text("Green Component")
                            Slider(value: $settings.greenComponent, in: 0.0...1.0)
                                .padding()
                        }

                        HStack {
                            Text("Blue Component")
                            Slider(value: $settings.blueComponent, in: 0.0...1.0)
                                .padding()
                        }
                    }
                    .padding()

                    // Distortion Controls
                    VStack {
                        Text("Distortion Controls").font(.headline)
                        Toggle("Enable Distortion", isOn: $settings.distortionMode)
                            .padding()

                        if settings.distortionMode {
                            HStack {
                                Text("Distortion Ratio")
                                Slider(value: $settings.distortionRatio, in: 0.0...1.0)
                                    .padding()
                            }

                            HStack {
                                Text("Distortion Shape")
                                Slider(value: $settings.distortionShape, in: 0.1...3.0)
                                    .padding()
                            }

                            HStack {
                                Text("Distortion Frequency Relation")
                                Slider(value: $settings.distortionFrequencyRelation, in: 0.1...2.0)
                                    .padding()
                            }

                            HStack {
                                Text("Chaos Factor")
                                Slider(value: $settings.chaosFactor, in: 0.0...1.0)
                                    .padding()
                            }
                        }
                    }
                    .padding()

                    // Perlin Noise Controls
                    VStack {
                        Text("Perlin Noise Controls").font(.headline)
                        Toggle("Enable Perlin Noise", isOn: $settings.perlinMode)
                            .padding()
                        
                        if settings.perlinMode {
                            HStack {
                                Text("Perlin Intensity")
                                Slider(value: $settings.perlinIntensity, in: 0.0...1.0)
                                    .padding()
                            }
                            
                            HStack {
                                Text("Perlin Scale")
                                Slider(value: $settings.perlinScale, in: 0.1...5.0)
                                    .padding()
                            }
                            
                            HStack {
                                Text("Perlin Frequency")
                                Slider(value: $settings.perlinFrequency, in: 0.1...2.0)
                                    .padding()
                            }
                            
                            Picker("Blending Mode", selection: $settings.perlinBlendMode) {
                                ForEach(BlendMode.allCases, id: \.self) { mode in
                                    Text(mode.name).tag(mode)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                        }
                    }
                    .padding()
                    
                    VStack {
                        Text("Kaleidoscope and Warp Controls").font(.headline)
                        Toggle("Enable Kaleidoscope Mode", isOn: $settings.kaleidoscopeMode)
                            .padding()

                        if settings.kaleidoscopeMode {
                            HStack {
                                Text("Kaleidoscope Segments")
                                Slider(value: Binding(
                                    get: {
                                        Float(settings.kaleidoscopeSegments)
                                    },
                                    set: {
                                        settings.kaleidoscopeSegments = Int($0)
                                    }
                                ), in: 3...20, step: 1)
                                .padding()
                            }
                        }

                        HStack {
                            Text("Warp Intensity")
                            Slider(value: $settings.warpIntensity, in: 0.1...1.0)
                                .padding()
                        }

                        HStack {
                            Text("Twist Intensity")
                            Slider(value: $settings.twistIntensity, in: 0.0...1.0)
                                .padding()
                        }
                    }
                        .padding()
                }
                .tabViewStyle(PageTabViewStyle())
            }
            .padding(.horizontal)
        }
    }
}
