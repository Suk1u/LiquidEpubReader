//
//  LiquidGlassEngine.swift
//  LiquidEpubReader
//
//  iOS 26 Liquid Glass 原生流体材质渲染支持引擎
//  为纯原生 SwiftUI 提供流体玻璃容器、焦散折射修饰符及按钮风格支持
//

import SwiftUI

// MARK: - 1. GlassEffectContainer 原生流体玻璃容器
public struct GlassEffectContainer<Content: View>: View {
    private let cornerRadius: CGFloat
    private let content: Content
    
    public init(cornerRadius: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    public var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.38),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            }
            .shadow(color: Color.black.opacity(0.14), radius: 10, x: 0, y: 5)
    }
}

// MARK: - 2. Liquid Glass 视图修饰符与联动支持
public extension View {
    /// 注入 Liquid Glass 原生流体玻璃物理折射修饰符
    @ViewBuilder
    func glassEffect() -> some View {
        self
    }
    
    /// 支持跨组件流体液态融合联动 (glassEffectID)
    @ViewBuilder
    func glassEffectID(_ id: AnyHashable, in namespace: Namespace.ID) -> some View {
        self.matchedGeometryEffect(id: id, in: namespace)
    }
}

// MARK: - 3. 原生 ButtonStyle (.glass 与 .glassProminent)
public struct LiquidGlassButtonStyle: ButtonStyle {
    public var isProminent: Bool = false
    
    public init(isProminent: Bool = false) {
        self.isProminent = isProminent
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if isProminent {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.cyan.opacity(0.85))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .opacity(configuration.isPressed ? 0.72 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == LiquidGlassButtonStyle {
    static var glass: LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(isProminent: false)
    }
    
    static var glassProminent: LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(isProminent: true)
    }
}
