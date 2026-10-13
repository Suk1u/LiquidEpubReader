# LiquidEpubReader - iOS 26 Liquid Glass 原生 EPUB 阅读器

[![Build Unsigned IPA](https://github.com/Suk1u/LiquidEpubReader/actions/workflows/build-ipa.yml/badge.svg)](https://github.com/Suk1u/LiquidEpubReader/actions/workflows/build-ipa.yml)
[![Platform](https://img.shields.io/badge/Platform-iOS%2026.0%2B%20%7C%20visionOS%202.0%2B-blue.svg)](https://developer.apple.com)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Apple%20HIG%20Liquid%20Glass-cyan.svg)](https://developer.apple.com/swiftui)
[![Build Environment](https://img.shields.io/badge/Build%20Environment-Xcode%2026%2B%20SDK-purple.svg)](https://developer.apple.com/xcode)

> **⚠️ 编译环境强依赖声明 (Mandatory)**  
> 本项目严格基于 **Apple HIG 空间与流体材质设计规范 (Liquid Glass Native Design System)** 开发。  
> **必须使用 Xcode 26 SDK 编译，仅修改 deployment target 不会启用原生流体玻璃渲染效果。**  
> 全量代码纯原生直出，零手写 Polyfill 拟态垫片，零第三方非官方外部依赖。

---

## 📖 核心特性与架构拆解

### 1. 流体书架 (Bookshelf View)
- **空间流体检索**: 基于 `GlassEffectContainer` 承载的实时搜索框与分段选择器（全部馆藏 / 最近在读 / 星标收藏）。
- **精选阅读流体卡片**: 动态光泽焦散流动，一键回溯至上次阅读进度。
- **自适应书籍网格 (`LazyVGrid`)**: 融合原生 `.glassEffect()` 与 `.glassEffectID`，书本卡片悬浮与折射下层渐变背景。
- **全量无障碍支持**: 覆盖每一个按钮与进度条的 `.accessibilityLabel` 及动态 `.accessibilityValue`。

### 2. 沉浸式流体阅读器 (Immersive Reader Canvas)
- **触控灵动 HUD**: 轻点页面任意空白区域，以原生弹簧动画折射唤出/隐退顶部与底部流体控制岛。
- **顶部流体导航岛 (`topNavigationIsland`)**:
  - 返回书架与书籍/章节层级动态指示
  - 目录与书签呼出
  - 收藏/星标即时切换
  - 排版与材质设置
- **底部流体控制岛 (`bottomControlIsland`)**:
  - 动态章节进度滑块，实时计算整书百分比与章节跳转
  - 原生流体玻璃样式翻章按键 (`.buttonStyle(.glass)`)
  - 章节胶囊指示徽章与 `.glassEffectID` 联动
- **多维度排版定制**:
  - 支持 **系统原生 / 人文衬线 / 温润圆体** 字体设计
  - 字号与行间距平滑滑动调节
  - 4 大沉浸主题：`流体玻璃 (Liquid Glass)`、`极简纸白`、`暖黄羊皮`、`午夜深空`

### 3. 原生浮层与大纲 (Native Sheets)
- **目录与大纲 (`TableOfContentsSheet`)**: 原生 `.sheet` 承载，清晰标注正在阅读章节与快速跳转。
- **排版与流体材质调谐 (`AppearanceSettingsSheet`)**: 动态调节流体玻璃焦散折射度（0.1 ~ 1.0），适配系统“减少透明度”无障碍设置。

---

## 🎨 原生 Liquid Glass API 清单

本项目严格遵守 `swiftui-ios26design-native-ui-builder` 规范白名单：

| 原生组件 / 修饰符 | 应用场景 |
| :--- | :--- |
| `.glassEffect()` | 注入系统级物理焦散折射管线 |
| `GlassEffectContainer` | 流体玻璃材质统一聚合容器，自动处理深度与边缘光晕 |
| `.glassEffectID(_:in:)` | 顶部导航岛、底部控制岛与网格项之间的液态流体形变联动 |
| `.buttonStyle(.glass)` | 晶莹轻盈的原生玻璃按钮材质 |
| `.buttonStyle(.glassProminent)` | 高对比度主视觉重点操作按钮 |
| `.accessibilityLabel(...)` / `.accessibilityValue(...)` | 100% 交互控件语义无障碍覆盖 |

---

## 🚀 GitHub Actions 自动化打包未签名 IPA

本项目内置全自动 GitHub Actions CI 工作流 (`.github/workflows/build-ipa.yml`)：

1. **自动触发**: 每当 `main` 分支有代码推送或手动执行 `workflow_dispatch` 时自动运行。
2. **Bundle 组装**: 组装合规的标准 iOS App 目录结构，包含 `Info.plist`、`PkgInfo`、`arm64` 机器码执行入口与源码资源。
3. **未签名打包**: 自动封装 `Payload/LiquidEpubReader.app` 为 `LiquidEpubReader-unsigned.ipa`。
4. **工件下载**: 运行完成后可在 GitHub Actions 的 **Artifacts** 区域直接下载未签名 `.ipa` 安装包。

### 侧载安装指引 (Sideloading)
- **TrollStore (巨魔)**: 直接导入 `LiquidEpubReader-unsigned.ipa` 即可永久免签名安装。
- **AltStore / SideStore**: 使用个人 Apple ID 签名后即可侧载至真机运行。
- **Sideloadly**: 拖拽 `.ipa` 并在电脑端输入 Apple ID 进行免越狱签名安装。

---

## 📂 项目结构

```text
LiquidEpubReader/
├── LiquidEpubReaderView.swift   # 遵循 iOS 26 Liquid Glass 规范的核心单文件实现
├── LiquidEpubReaderApp.swift    # 应用 @main 启动入口
├── Info.plist                   # iOS 26+ 应用配置清单与权限声明
├── .github/
│   └── workflows/
│       └── build-ipa.yml        # GitHub Actions 自动化未签名 IPA 打包脚本
├── .gitignore                   # Git 忽略配置
└── README.md                    # 项目设计规范与使用指南
```

---

## 📄 授权许可
MIT License © 2026 Suk1u
