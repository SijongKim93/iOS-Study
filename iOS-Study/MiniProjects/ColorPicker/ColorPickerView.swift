//
//  ColorPickerView.swift
//  iOS-Study
//
//  Created by GPT-5 Codex on 11/10/25.
//

import SwiftUI

struct ColorPickerView: View {
    @StateObject private var viewModel = ColorPickerViewModel()
    
    var body: some View {
        List {
            Section("색상 선택") {
                ColorPicker("배경색", selection: $viewModel.backgroundColor, supportsOpacity: false)
                
                ColorPicker("텍스트색", selection: $viewModel.textColor, supportsOpacity: false)
                
                Toggle("그라데이션 사용", isOn: $viewModel.useGradient)
                
                if viewModel.useGradient {
                    ColorPicker("그라데이션 색상", selection: $viewModel.gradientColor, supportsOpacity: false)
                }
            }
            
            Section("미리보기") {
                VStack(spacing: 20) {
                    Text("안녕하세요!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.textColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.useGradient
                                ? LinearGradient(
                                    colors: [viewModel.backgroundColor, viewModel.gradientColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [viewModel.backgroundColor],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .cornerRadius(16)
                    
                    Text("SwiftUI 색상 선택 예제")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            
            Section("색상 정보") {
                HStack {
                    Label("배경색", systemImage: "paintpalette")
                    Spacer()
                    Text(viewModel.backgroundColorHex)
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Label("텍스트색", systemImage: "textformat")
                    Spacer()
                    Text(viewModel.textColorHex)
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .navigationTitle("색상 선택기")
    }
}

// MARK: - View Model

@MainActor
final class ColorPickerViewModel: ObservableObject {
    @Published var backgroundColor: Color = .blue
    @Published var textColor: Color = .white
    @Published var useGradient: Bool = false
    @Published var gradientColor: Color = .purple
    
    var backgroundColorHex: String {
        hexString(from: backgroundColor)
    }
    
    var textColorHex: String {
        hexString(from: textColor)
    }
    
    private func hexString(from color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

#Preview {
    NavigationStack {
        ColorPickerView()
    }
}

