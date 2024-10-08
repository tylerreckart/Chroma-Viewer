//
//  MetalRenderer.swift
//  Chroma Viewer
//
//  Created by Tyler Reckart on 10/4/24.
//

import Foundation
import SwiftUI
import MetalKit

class MetalRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var fluidPipelineState: MTLRenderPipelineState!
    var wavePipelineState: MTLRenderPipelineState!
    var visualizerType: VisualizerType = .fluid
    var settings: VisualizerSettings

    init(device: MTLDevice, settings: VisualizerSettings) {
        self.device = device
        self.settings = settings
        self.commandQueue = device.makeCommandQueue()
        super.init()
        setupPipelines()
    }

    // Set up Metal pipelines for different visualizers
    private func setupPipelines() {
        let library = device.makeDefaultLibrary()

        // Fluid visualizer pipeline
        let fluidVertexFunction = library?.makeFunction(name: "vertex_main")
        let fluidFragmentFunction = library?.makeFunction(name: "fragment_main")
        let fluidPipelineDescriptor = MTLRenderPipelineDescriptor()
        fluidPipelineDescriptor.vertexFunction = fluidVertexFunction
        fluidPipelineDescriptor.fragmentFunction = fluidFragmentFunction
        fluidPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            fluidPipelineState = try device.makeRenderPipelineState(descriptor: fluidPipelineDescriptor)
        } catch {
            fatalError("Failed to create fluid pipeline state: \(error)")
        }

        // Wave visualizer pipeline (example)
        let waveVertexFunction = library?.makeFunction(name: "vertex_main")
        let waveFragmentFunction = library?.makeFunction(name: "wave_fragment_main") // Assume this is a different shader
        let wavePipelineDescriptor = MTLRenderPipelineDescriptor()
        wavePipelineDescriptor.vertexFunction = waveVertexFunction
        wavePipelineDescriptor.fragmentFunction = waveFragmentFunction
        wavePipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            wavePipelineState = try device.makeRenderPipelineState(descriptor: wavePipelineDescriptor)
        } catch {
            fatalError("Failed to create wave pipeline state: \(error)")
        }
    }
    
    func update(amplitude: Float, pitch: Float) {
        settings.amplitude = amplitude
        settings.pitch = pitch
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle view size changes if necessary
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable, let descriptor = view.currentRenderPassDescriptor else { return }

        // Update the time for animation
        settings.time += settings.timeIncrement * 0.05

        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)

        // Select the pipeline state based on the visualizer type
        switch visualizerType {
        case .fluid:
            commandEncoder?.setRenderPipelineState(fluidPipelineState)
        case .wave:
            commandEncoder?.setRenderPipelineState(wavePipelineState)
        }

        // Apply amplitude and pitch sensitivity
        var scaledAmplitude = settings.amplitude * settings.amplitudeSensitivity
        var scaledPitch = settings.pitch * settings.pitchSensitivity

        // Set up evolving gradient parameters based on settings
        let brightness = max(0.2, settings.brightnessMultiplier) // Keep brightness above a base level
        var gradientColor = SIMD4<Float>(scaledAmplitude, 1.0 - scaledAmplitude, brightness, 1.0)

        // Pass updated parameters to the fragment shader
        commandEncoder?.setFragmentBytes(&gradientColor, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
        commandEncoder?.setFragmentBytes(&settings.time, length: MemoryLayout<Float>.stride, index: 1)
        commandEncoder?.setFragmentBytes(&settings.colorMixFactor, length: MemoryLayout<Float>.stride, index: 2)
        commandEncoder?.setFragmentBytes(&settings.baseHueOffset, length: MemoryLayout<Float>.stride, index: 3)
        commandEncoder?.setFragmentBytes(&settings.redComponent, length: MemoryLayout<Float>.stride, index: 4)
        commandEncoder?.setFragmentBytes(&settings.greenComponent, length: MemoryLayout<Float>.stride, index: 5)
        commandEncoder?.setFragmentBytes(&settings.blueComponent, length: MemoryLayout<Float>.stride, index: 6)
        commandEncoder?.setFragmentBytes(&settings.brightnessMultiplier, length: MemoryLayout<Float>.stride, index: 7)
        commandEncoder?.setFragmentBytes(&settings.animationShapeFactor, length: MemoryLayout<Float>.stride, index: 8)
        commandEncoder?.setFragmentBytes(&scaledAmplitude, length: MemoryLayout<Float>.stride, index: 9)
        commandEncoder?.setFragmentBytes(&scaledPitch, length: MemoryLayout<Float>.stride, index: 10)
        commandEncoder?.setFragmentBytes(&settings.distortionMode, length: MemoryLayout<Bool>.stride, index: 11)
        commandEncoder?.setFragmentBytes(&settings.distortionRatio, length: MemoryLayout<Float>.stride, index: 12)
        commandEncoder?.setFragmentBytes(&settings.distortionShape, length: MemoryLayout<Float>.stride, index: 13)
        commandEncoder?.setFragmentBytes(&settings.distortionFrequencyRelation, length: MemoryLayout<Float>.stride, index: 14)
        commandEncoder?.setFragmentBytes(&settings.chaosFactor, length: MemoryLayout<Float>.stride, index: 15)
        commandEncoder?.setFragmentBytes(&settings.perlinMode, length: MemoryLayout<Bool>.stride, index: 16)
        commandEncoder?.setFragmentBytes(&settings.perlinIntensity, length: MemoryLayout<Float>.stride, index: 17)
        commandEncoder?.setFragmentBytes(&settings.perlinScale, length: MemoryLayout<Float>.stride, index: 18)
        commandEncoder?.setFragmentBytes(&settings.perlinFrequency, length: MemoryLayout<Float>.stride, index: 19)
        commandEncoder?.setFragmentBytes(&settings.kaleidoscopeMode, length: MemoryLayout<Bool>.stride, index: 20)
        commandEncoder?.setFragmentBytes(&settings.kaleidoscopeSegments, length: MemoryLayout<Int>.stride, index: 21)
        commandEncoder?.setFragmentBytes(&settings.warpIntensity, length: MemoryLayout<Float>.stride, index: 22)
        commandEncoder?.setFragmentBytes(&settings.twistIntensity, length: MemoryLayout<Float>.stride, index: 23)
        var perlinBlendModeRawValue = settings.perlinBlendMode.rawValue
        commandEncoder?.setFragmentBytes(&perlinBlendModeRawValue, length: MemoryLayout<Int>.stride, index: 24)
        commandEncoder?.setFragmentBytes(&settings.glitchMode, length: MemoryLayout<Bool>.stride, index: 25)
        commandEncoder?.setFragmentBytes(&settings.glitchFrequency, length: MemoryLayout<Float>.stride, index: 26)
        commandEncoder?.setFragmentBytes(&settings.glitchSize, length: MemoryLayout<Float>.stride, index: 27)
        commandEncoder?.setFragmentBytes(&settings.colorShiftSpeed, length: MemoryLayout<Float>.stride, index: 28)

        // Draw a full-screen quad
        commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: Int(6 * settings.animationShapeFactor))

        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }

}

struct MetalViewRepresentable: UIViewRepresentable {
    @ObservedObject var audioManager: AudioInputManager
    var renderer: MetalRenderer

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = renderer
        mtkView.framebufferOnly = false
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        renderer.update(amplitude: audioManager.amplitude, pitch: audioManager.pitch)
    }
}
