//
//  LiquidEpubReaderApp.swift
//  LiquidEpubReader
//
//  提示：必须使用 Xcode 26 SDK 编译，仅修改 deployment target 不会启用原生流体玻璃渲染效果。
//

import SwiftUI

@main
struct LiquidEpubReaderApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(iOS 26.0, *) {
                LiquidEpubReaderRootView()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.yellow)
                    Text("需要 iOS 26.0 或更高版本")
                        .font(.headline)
                    Text("本应用严格基于 iOS 26 Liquid Glass 原生渲染管线构建，请在兼容系统设备或 Xcode 26+ 模拟器上运行。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding()
            }
        }
    }
}
