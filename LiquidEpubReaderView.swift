//
//  LiquidEpubReaderView.swift
//  LiquidEpubReader
//
//  提示：必须使用 Xcode 26 SDK 编译，仅修改 deployment target 不会启用原生流体玻璃渲染效果。
//  遵循 Apple HIG 空间与流体材质设计规范，面向 iOS 26.0+ / visionOS 2.0+。
//  采用原生 Liquid Glass 渲染引擎与纯原生控件白名单，零 Polyfill 垫片。
//

import SwiftUI

// MARK: - 数据模型与状态定义

public struct EpubChapter: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let index: Int
    public let title: String
    public let content: [String]
    
    public init(id: UUID = UUID(), index: Int, title: String, content: [String]) {
        self.id = id
        self.index = index
        self.title = title
        self.content = content
    }
}

public struct EpubBook: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var author: String
    public var coverSymbol: String
    public var coverTint: Color
    public var chapters: [EpubChapter]
    public var currentChapterIndex: Int
    public var progress: Double // 0.0 - 1.0
    public var isFavorite: Bool
    
    public init(
        id: UUID = UUID(),
        title: String,
        author: String,
        coverSymbol: String,
        coverTint: Color,
        chapters: [EpubChapter],
        currentChapterIndex: Int = 0,
        progress: Double = 0.0,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.coverSymbol = coverSymbol
        self.coverTint = coverTint
        self.chapters = chapters
        self.currentChapterIndex = currentChapterIndex
        self.progress = progress
        self.isFavorite = isFavorite
    }
}

public enum ReaderTheme: String, CaseIterable, Identifiable, Sendable {
    case liquidGlass = "流体玻璃"
    case paperLight = "极简纸白"
    case warmSepia = "暖黄羊皮"
    case deepMidnight = "午夜深空"
    
    public var id: String { rawValue }
    
    public var backgroundGradient: [Color] {
        switch self {
        case .liquidGlass:
            return [Color(red: 0.12, green: 0.16, blue: 0.28), Color(red: 0.05, green: 0.08, blue: 0.15)]
        case .paperLight:
            return [Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.94, green: 0.93, blue: 0.90)]
        case .warmSepia:
            return [Color(red: 0.95, green: 0.90, blue: 0.82), Color(red: 0.88, green: 0.82, blue: 0.72)]
        case .deepMidnight:
            return [Color(red: 0.04, green: 0.04, blue: 0.06), Color(red: 0.01, green: 0.01, blue: 0.02)]
        }
    }
    
    public var textColor: Color {
        switch self {
        case .liquidGlass, .deepMidnight:
            return Color.white.opacity(0.92)
        case .paperLight:
            return Color.black.opacity(0.88)
        case .warmSepia:
            return Color(red: 0.24, green: 0.18, blue: 0.12)
        }
    }
}

public enum TypographyStyle: String, CaseIterable, Identifiable, Sendable {
    case system = "系统原生"
    case serif = "人文衬线"
    case rounded = "温润圆体"
    
    public var id: String { rawValue }
    
    public var fontDesign: Font.Design {
        switch self {
        case .system: return .default
        case .serif: return .serif
        case .rounded: return .rounded
        }
    }
}

// MARK: - 主容器与视图入口

@available(iOS 17.0, *)
public struct LiquidEpubReaderRootView: View {
    @State private var books: [EpubBook] = MockEpubDataProvider.sampleLibrary
    @State private var selectedBook: EpubBook? = nil
    @State private var searchQuery: String = ""
    @State private var filterSelection: Int = 0 // 0: 全部, 1: 正在阅读, 2: 收藏
    
    @Namespace private var glassEffectNamespace
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // 动态背景流体层
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.09, blue: 0.18),
                        Color(red: 0.02, green: 0.03, blue: 0.07)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 书架主内容
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 顶部流体过滤与状态胶囊
                        headerControls
                        
                        // 最近阅读精选流体卡片
                        if let featured = books.first {
                            featuredBookBanner(book: featured)
                        }
                        
                        // 书籍网格
                        booksGrid
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("流体书藏")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        importNewMockBook()
                    } label: {
                        Label("导入书籍", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("导入新的 EPUB 书籍")
                }
            }
            .fullScreenCover(item: $selectedBook) { book in
                EpubReaderDetailView(book: binding(for: book))
            }
        }
    }
    
    // MARK: - 顶部流体过滤面板
    
    @ViewBuilder
    private var headerControls: some View {
        GlassEffectContainer {
            VStack(spacing: 14) {
                // 原生搜索框
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    TextField("搜索书名、作者或章节...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .accessibilityLabel("搜索书架书籍")
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("清空搜索框")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // 分段选择器
                Picker("书架分类", selection: $filterSelection) {
                    Text("全部馆藏").tag(0)
                    Text("最近阅读").tag(1)
                    Text("星标收藏").tag(2)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("书架分类筛选")
            }
            .padding(16)
        }
        .glassEffect()
        .glassEffectID("bookshelfHeaderFilter", in: glassEffectNamespace)
    }
    
    // MARK: - 精选流体卡片
    
    @ViewBuilder
    private func featuredBookBanner(book: EpubBook) -> some View {
        GlassEffectContainer {
            HStack(spacing: 18) {
                // 封面
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(book.coverTint.gradient)
                    Image(systemName: book.coverSymbol)
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(width: 86, height: 118)
                .shadow(color: book.coverTint.opacity(0.35), radius: 12, x: 0, y: 8)
                .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("当前在读")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(book.progress * 100))%")
                            .font(.caption.bold())
                            .foregroundStyle(.tint)
                    }
                    
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 4)
                    
                    Button {
                        selectedBook = book
                    } label: {
                        HStack(spacing: 6) {
                            Text("继续阅读")
                            Image(systemName: "book.pages.fill")
                        }
                        .font(.footnote.weight(.semibold))
                    }
                    .buttonStyle(.glassProminent)
                    .accessibilityLabel("继续阅读《\(book.title)》")
                }
            }
            .padding(16)
        }
        .glassEffect()
        .glassEffectID("featuredBookCard_\(book.id)", in: glassEffectNamespace)
    }
    
    // MARK: - 书架网格
    
    @ViewBuilder
    private var booksGrid: some View {
        let filtered = filteredBooks
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 18)], spacing: 20) {
            ForEach(filtered) { book in
                Button {
                    selectedBook = book
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        // 书籍封面
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(book.coverTint.gradient)
                                .aspectRatio(0.72, contentMode: .fit)
                            
                            Image(systemName: book.coverSymbol)
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(.white.opacity(0.88))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            if book.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                                    .padding(8)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .padding(8)
                            }
                        }
                        .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 6)
                        
                        // 书籍元信息
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.callout.bold())
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            Text(book.author)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            
                            ProgressView(value: book.progress)
                                .progressViewStyle(.linear)
                                .tint(book.coverTint)
                                .padding(.top, 4)
                                .accessibilityLabel("阅读进度")
                                .accessibilityValue("\(Int(book.progress * 100)) 百分比")
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)
                .glassEffect()
                .glassEffectID("bookGridItem_\(book.id)", in: glassEffectNamespace)
                .accessibilityLabel("书籍《\(book.title)》，作者 \(book.author)，已读 \(Int(book.progress * 100))%")
            }
        }
    }
    
    private var filteredBooks: [EpubBook] {
        books.filter { book in
            let matchesSearch = searchQuery.isEmpty ||
                book.title.localizedCaseInsensitiveContains(searchQuery) ||
                book.author.localizedCaseInsensitiveContains(searchQuery)
            
            let matchesFilter: Bool
            switch filterSelection {
            case 1: matchesFilter = book.progress > 0 && book.progress < 1.0
            case 2: matchesFilter = book.isFavorite
            default: matchesFilter = true
            }
            
            return matchesSearch && matchesFilter
        }
    }
    
    private func binding(for book: EpubBook) -> Binding<EpubBook> {
        Binding(
            get: { books.first(where: { $0.id == book.id }) ?? book },
            set: { updated in
                if let index = books.firstIndex(where: { $0.id == updated.id }) {
                    books[index] = updated
                }
            }
        )
    }
    
    private func importNewMockBook() {
        let newBook = EpubBook(
            title: "流体设计空间哲学",
            author: "Apple Human Interface",
            coverSymbol: "sparkles.rectangle.stack.fill",
            coverTint: Color.cyan,
            chapters: [
                EpubChapter(
                    index: 0,
                    title: "第 1 章：光与流体的折射共鸣",
                    content: [
                        "流体玻璃（Liquid Glass）并非平面的模糊覆盖层，而是将物理折射、焦散流动与空间深度合而为一的动态计算材质。",
                        "在 iOS 26 中，界面元素脱离了固定像素容器的边界，彼此靠近时通过 glassEffectID 实现液态融合。",
                        "内容不再只是被陈列在玻璃之下，而是作为光源驱动折射渲染的核心介质。"
                    ]
                )
            ],
            progress: 0.0,
            isFavorite: true
        )
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            books.insert(newBook, at: 0)
        }
    }
}

// MARK: - EPUB 沉浸式阅读器界面

@available(iOS 17.0, *)
public struct EpubReaderDetailView: View {
    @Binding var book: EpubBook
    @Environment(\.dismiss) private var dismiss
    
    // 阅读状态驱动链
    @State private var isControlsVisible: Bool = true
    @State private var showTableOfContents: Bool = false
    @State private var showAppearanceSettings: Bool = false
    @State private var activeTheme: ReaderTheme = .liquidGlass
    @State private var typographyStyle: TypographyStyle = .serif
    @State private var fontSize: Double = 18.0
    @State private var lineSpacing: Double = 8.0
    @State private var refractionStrength: Double = 0.85
    
    @Namespace private var readerGlassNamespace
    
    public init(book: Binding<EpubBook>) {
        self._book = book
    }
    
    private var currentChapter: EpubChapter {
        let index = max(0, min(book.currentChapterIndex, book.chapters.count - 1))
        return book.chapters[index]
    }
    
    public var body: some View {
        ZStack {
            // 背景主题层
            LinearGradient(
                colors: activeTheme.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isControlsVisible.toggle()
                }
            }
            
            // 正文阅读排版流
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // 章节标题
                    Text(currentChapter.title)
                        .font(.system(size: fontSize + 8, weight: .bold, design: typographyStyle.fontDesign))
                        .foregroundStyle(activeTheme.textColor)
                        .padding(.top, 72)
                        .padding(.bottom, 8)
                        .accessibilityHeading(.h1)
                    
                    // 章节段落内容
                    ForEach(Array(currentChapter.content.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                            .font(.system(size: fontSize, weight: .regular, design: typographyStyle.fontDesign))
                            .lineSpacing(lineSpacing)
                            .foregroundStyle(activeTheme.textColor)
                            .padding(.bottom, 6)
                    }
                    
                    // 章节底部翻页指引
                    HStack {
                        Spacer()
                        Text("— 本章完 · 第 \(book.currentChapterIndex + 1) / \(book.chapters.count) 章 —")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 32)
                        Spacer()
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 120)
            }
            
            // 顶部与底部 HUD 浮动控制岛
            if isControlsVisible {
                VStack {
                    topNavigationIsland
                    Spacer()
                    bottomControlIsland
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.96)),
                    removal: .opacity.combined(with: .scale(scale: 0.98))
                ))
            }
        }
        .statusBarHidden(!isControlsVisible)
        .sheet(isPresented: $showTableOfContents) {
            TableOfContentsSheet(
                book: $book,
                currentIndex: book.currentChapterIndex
            )
        }
        .sheet(isPresented: $showAppearanceSettings) {
            AppearanceSettingsSheet(
                activeTheme: $activeTheme,
                typographyStyle: $typographyStyle,
                fontSize: $fontSize,
                lineSpacing: $lineSpacing,
                refractionStrength: $refractionStrength
            )
        }
    }
    
    // MARK: - 顶部流体导航岛
    
    @ViewBuilder
    private var topNavigationIsland: some View {
        GlassEffectContainer {
            HStack(spacing: 14) {
                // 返回书架
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(.glass)
                .accessibilityLabel("返回书藏")
                
                // 书籍标题
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Text(currentChapter.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 目录按钮
                Button {
                    showTableOfContents = true
                } label: {
                    Image(systemName: "list.bullet.rectangle.portrait")
                }
                .buttonStyle(.glass)
                .accessibilityLabel("打开目录大纲与书签")
                
                // 收藏/星标
                Button {
                    book.isFavorite.toggle()
                } label: {
                    Image(systemName: book.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(book.isFavorite ? .yellow : .primary)
                }
                .buttonStyle(.glass)
                .accessibilityLabel(book.isFavorite ? "取消收藏" : "加入收藏")
                
                // 阅读排版设置
                Button {
                    showAppearanceSettings = true
                } label: {
                    Image(systemName: "textformat.size")
                }
                .buttonStyle(.glass)
                .accessibilityLabel("调整排版样式与主题材质")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .glassEffect()
        .glassEffectID("topReaderIsland", in: readerGlassNamespace)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - 底部流体阅读控制岛
    
    @ViewBuilder
    private var bottomControlIsland: some View {
        GlassEffectContainer {
            VStack(spacing: 14) {
                // 章节进度条与百分比
                HStack(spacing: 12) {
                    Text("上一章")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    
                    Slider(
                        value: Binding(
                            get: { book.progress },
                            set: { newValue in
                                book.progress = newValue
                                updateChapterFromProgress(newValue)
                            }
                        ),
                        in: 0.0...1.0
                    )
                    .tint(.cyan)
                    .accessibilityLabel("整书阅读进度")
                    .accessibilityValue("\(Int(book.progress * 100)) 百分比")
                    
                    Text("\(Int(book.progress * 100))%")
                        .font(.caption2.monospacedDigit().bold())
                        .foregroundStyle(.primary)
                        .frame(width: 38, alignment: .trailing)
                }
                
                // 翻章操作按钮
                HStack(spacing: 20) {
                    Button {
                        if book.currentChapterIndex > 0 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                book.currentChapterIndex -= 1
                                syncProgressWithChapter()
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.backward.circle")
                            Text("上一章")
                        }
                    }
                    .buttonStyle(.glass)
                    .disabled(book.currentChapterIndex == 0)
                    .accessibilityLabel("跳转到上一章")
                    
                    Spacer()
                    
                    Text("\(book.currentChapterIndex + 1) / \(book.chapters.count)")
                        .font(.caption.monospacedDigit().weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .accessibilityLabel("当前第 \(book.currentChapterIndex + 1) 章，共 \(book.chapters.count) 章")
                    
                    Spacer()
                    
                    Button {
                        if book.currentChapterIndex < book.chapters.count - 1 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                book.currentChapterIndex += 1
                                syncProgressWithChapter()
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("下一章")
                            Image(systemName: "arrow.forward.circle")
                        }
                    }
                    .buttonStyle(.glass)
                    .disabled(book.currentChapterIndex >= book.chapters.count - 1)
                    .accessibilityLabel("跳转到下一章")
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .glassEffect()
        .glassEffectID("bottomReaderIsland", in: readerGlassNamespace)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    private func syncProgressWithChapter() {
        guard !book.chapters.isEmpty else { return }
        book.progress = Double(book.currentChapterIndex) / Double(max(1, book.chapters.count - 1))
    }
    
    private func updateChapterFromProgress(_ progress: Double) {
        guard !book.chapters.isEmpty else { return }
        let targetIndex = Int(round(progress * Double(book.chapters.count - 1)))
        book.currentChapterIndex = max(0, min(targetIndex, book.chapters.count - 1))
    }
}

// MARK: - 目录与大纲原生浮层 (Table of Contents Sheet)

@available(iOS 17.0, *)
public struct TableOfContentsSheet: View {
    @Binding var book: EpubBook
    let currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    public init(book: Binding<EpubBook>, currentIndex: Int) {
        self._book = book
        self.currentIndex = currentIndex
    }
    
    public var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(book.chapters) { chapter in
                        Button {
                            book.currentChapterIndex = chapter.index
                            book.progress = Double(chapter.index) / Double(max(1, book.chapters.count - 1))
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(chapter.index == currentIndex ? Color.cyan : Color.secondary.opacity(0.2))
                                        .frame(width: 28, height: 28)
                                    Text("\(chapter.index + 1)")
                                        .font(.caption2.bold())
                                        .foregroundStyle(chapter.index == currentIndex ? Color.black : Color.primary)
                                }
                                
                                Text(chapter.title)
                                    .font(.body.weight(chapter.index == currentIndex ? .semibold : .regular))
                                    .foregroundStyle(chapter.index == currentIndex ? .primary : .secondary)
                                
                                Spacer()
                                
                                if chapter.index == currentIndex {
                                    Image(systemName: "bookmark.fill")
                                        .foregroundStyle(.cyan)
                                        .accessibilityLabel("正在阅读章节")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .accessibilityLabel("第 \(chapter.index + 1) 章：\(chapter.title)\(chapter.index == currentIndex ? "，当前在读" : "")")
                    }
                } header: {
                    Text("全书章节目录（共 \(book.chapters.count) 章）")
                }
            }
            .navigationTitle("目录与书签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                    .accessibilityLabel("关闭目录")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - 排版与流体材质设置浮层 (Appearance Settings Sheet)

@available(iOS 17.0, *)
public struct AppearanceSettingsSheet: View {
    @Binding var activeTheme: ReaderTheme
    @Binding var typographyStyle: TypographyStyle
    @Binding var fontSize: Double
    @Binding var lineSpacing: Double
    @Binding var refractionStrength: Double
    @Environment(\.dismiss) private var dismiss
    
    public init(
        activeTheme: Binding<ReaderTheme>,
        typographyStyle: Binding<TypographyStyle>,
        fontSize: Binding<Double>,
        lineSpacing: Binding<Double>,
        refractionStrength: Binding<Double>
    ) {
        self._activeTheme = activeTheme
        self._typographyStyle = typographyStyle
        self._fontSize = fontSize
        self._lineSpacing = lineSpacing
        self._refractionStrength = refractionStrength
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // 主题选择
                Section("视觉主题材质") {
                    Picker("阅读背景主题", selection: $activeTheme) {
                        ForEach(ReaderTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("选择阅读背景主题")
                }
                
                // 字体系列
                Section("排版字体系列") {
                    Picker("字体风格", selection: $typographyStyle) {
                        ForEach(TypographyStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("选择排版字体系列")
                }
                
                // 字号与行间距调节
                Section("版式微调") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("阅读字号", systemImage: "textformat.size.larger")
                            Spacer()
                            Text("\(Int(fontSize)) pt")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $fontSize, in: 14.0...32.0, step: 1.0)
                            .tint(.cyan)
                            .accessibilityLabel("调整阅读字号")
                            .accessibilityValue("\(Int(fontSize)) 磅")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("行间距", systemImage: "arrow.up.and.down.text.horizontal")
                            Spacer()
                            Text("\(Int(lineSpacing)) pt")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $lineSpacing, in: 4.0...18.0, step: 1.0)
                            .tint(.cyan)
                            .accessibilityLabel("调整行间距")
                            .accessibilityValue("\(Int(lineSpacing)) 磅")
                    }
                }
                
                // 原生 Liquid Glass 折射强度
                Section(header: Text("iOS 26 原生 Liquid Glass 材质"), footer: Text("流体物理折射管线基于 Xcode 26 SDK 原生编译驱动，支持系统无障碍透明度调谐。")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("焦散折射度", systemImage: "sparkles")
                            Spacer()
                            Text("\(Int(refractionStrength * 100))%")
                                .monospacedDigit()
                                .foregroundStyle(.cyan)
                        }
                        Slider(value: $refractionStrength, in: 0.1...1.0)
                            .tint(.cyan)
                            .accessibilityLabel("流体玻璃焦散折射强度")
                            .accessibilityValue("\(Int(refractionStrength * 100)) 百分比")
                    }
                }
            }
            .navigationTitle("排版与材质")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                    .accessibilityLabel("完成排版设置")
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - 模拟 EPUB 经典书籍数据源

public enum MockEpubDataProvider {
    public static var sampleLibrary: [EpubBook] {
        [
            EpubBook(
                title: "小王子",
                author: "安托万·德·圣-埃克苏佩里",
                coverSymbol: "star.circle.fill",
                coverTint: Color(red: 0.95, green: 0.65, blue: 0.25),
                chapters: [
                    EpubChapter(
                        index: 0,
                        title: "第 1 章：蟒蛇与巨蟒的消化",
                        content: [
                            "六岁那年，我在一本描写原始森林的书里看到了一幅精彩绝伦的插图，书名叫《真实的故事》。画面上画着一条正在吞咽野兽的蟒蛇。",
                            "书里写道：'大蟒蛇会把猎物囫囵吞下，连嚼都不嚼。之后它们就动弹不得了，需要沉睡六个月来进行消化。'",
                            "于是我对丛林里的冒险冥思苦想，拿彩色铅笔画出了我平生的第一幅杰作。那就是我的第一号画作，它看起来就像一顶帽子。",
                            "大人们却对我说，别去管什么大蟒蛇肚皮开着或闭着的画了，还是把精力放在地理、历史、算术和语法上吧。"
                        ]
                    ),
                    EpubChapter(
                        index: 1,
                        title: "第 2 章：沙漠中的相遇与绵羊",
                        content: [
                            "于是我就这样孤单地生活着，没有一个能真正推心置腹说话的人，直到六年前我的飞机在撒哈拉沙漠出了故障。",
                            "发动机里有什么东西碎了。因为我身边既没有机械师也没有乘客，我只能硬着头皮独自尝试艰难的修理工作。这对我来说是生死攸关的事：我带的水勉强够喝一个星期。",
                            "第一天晚上，我在远离人烟一千英里的沙漠上睡着了。我比大海中漂浮的遇难船员还要孤立无援。",
                            "当黎明破晓时，一个微弱而奇怪的声音将我唤醒。那声音说：'请……给我画一只绵羊吧！'"
                        ]
                    ),
                    EpubChapter(
                        index: 2,
                        title: "第 3 章：来自另一颗星球",
                        content: [
                            "我花了很久才明白他是从哪里来的。小王子向我提了许多问题，却似乎从来不听我问他的话。",
                            "他偶然吐露出的片语只言，慢慢向我揭开了所有的秘密。比如，当他第一次看见我的飞机时，他问道：'那个庞然大物是什么？'",
                            "'那不是东西。它会飞。那是一架飞机，我的飞机。'我非常自豪地告诉他我会飞。",
                            "他接着喊道：'什么！你是从天上掉下来的吗？' '是的。'我谦逊地回答。'啊！这真有意思！'"
                        ]
                    )
                ],
                currentChapterIndex: 1,
                progress: 0.42,
                isFavorite: true
            ),
            EpubBook(
                title: "爱丽丝漫游奇境",
                author: "刘易斯·卡罗尔",
                coverSymbol: "suit.spade.fill",
                coverTint: Color(red: 0.35, green: 0.75, blue: 0.85),
                chapters: [
                    EpubChapter(
                        index: 0,
                        title: "第 1 章：掉进兔子洞",
                        content: [
                            "爱丽丝在河岸边坐着陪姐姐，无所事事，她开始觉得十分无聊。",
                            "她偶尔偷看一眼姐姐手里读的书，但书里既没有插图也没有对话。'如果一本书里既没有画也没有对话，'爱丽丝心想，'那它有什么用呢？'",
                            "就在这时，一只红眼睛的白兔突然从她身旁飞奔而过。",
                            "兔子从背心口袋里掏出一块怀表看了看，然后急匆匆地跑掉了。爱丽丝跳了起来，因为她意识到自己从未见过穿着有口袋背心的兔子！"
                        ]
                    ),
                    EpubChapter(
                        index: 1,
                        title: "第 2 章：眼泪的池塘",
                        content: [
                            "'真是越来越离奇了！'爱丽丝大声惊叫，她一时惊讶得连语法都忘了，'我现在正在像望远镜一样拉长！再见了，脚丫子！'",
                            "当她低头看自己的脚时，双脚已经几乎从视线里消失了，距离是那么遥远。",
                            "她的脑袋突然碰到了大厅的屋顶：事实上，她现在已经有九英尺多高了！"
                        ]
                    )
                ],
                currentChapterIndex: 0,
                progress: 0.15,
                isFavorite: false
            ),
            EpubBook(
                title: "iOS 26 流体人机交互指南",
                author: "Apple System Design",
                coverSymbol: "cube.transparent.fill",
                coverTint: Color(red: 0.72, green: 0.45, blue: 0.95),
                chapters: [
                    EpubChapter(
                        index: 0,
                        title: "第一章：Liquid Glass 流体物理渲染体系",
                        content: [
                            "在空间计算与多维设备深度融合的 iOS 26 时代，静态质感已被动态物理折射所取代。",
                            "Liquid Glass 是核心渲染基石：通过硬件加速的光线追踪管线，实时采样背景视差与环境光强，生成高保真焦散与折射效果。",
                            "开发者必须依赖 Xcode 26 SDK 原生编译支持，使用 .glassEffect() 与 GlassEffectContainer 容器构建界面层级。"
                        ]
                    ),
                    EpubChapter(
                        index: 1,
                        title: "第二章：跨组件流动关联 (glassEffectID)",
                        content: [
                            "当界面中存在多个流体玻璃岛时，通过 .glassEffectID(_:in:) 可以在命名空间内部建立液态连接。",
                            "当用户交互触发容器靠近或位移时，边缘的高光折射将动态变形并自然吸附融合，实现前所未有的生动触感。"
                        ]
                    )
                ],
                currentChapterIndex: 0,
                progress: 0.65,
                isFavorite: true
            )
        ]
    }
}

// MARK: - 预览组件

#Preview("流体书架主界面") {
    LiquidEpubReaderRootView()
}

#Preview("沉浸式阅读器与控制岛") {
    EpubReaderDetailView(
        book: .constant(MockEpubDataProvider.sampleLibrary[0])
    )
}
