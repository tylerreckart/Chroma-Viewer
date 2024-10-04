//
//  BlendMode.swift
//  Chroma Viewer
//
//  Created by Tyler Reckart on 10/4/24.
//

import Foundation

enum BlendMode: Int, CaseIterable {
    case normal = 0
    case multiply
    case screen
    case overlay
    case difference
    case hardLight
    case colorBurn

    var name: String {
        switch self {
        case .normal: return "Normal"
        case .multiply: return "Multiply"
        case .screen: return "Screen"
        case .overlay: return "Overlay"
        case .difference: return "Difference"
        case .hardLight: return "Hard Light"
        case .colorBurn: return "Color Burn"
        }
    }
}

