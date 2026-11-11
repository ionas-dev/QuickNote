// Renders final App Store screenshots (paper style) from raw simulator captures.
//
// Usage: compose <shots.json> <outRoot> [--only <id>]
// Writes <outRoot>/<locale>/<id>.png at exactly 1320 × 2868, sRGB, no alpha.
// Exits non-zero if a headline needs more than two lines at ≥ 90 % of the base size.

import AppKit
import CoreText
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Input

struct ShotsFile: Decodable {
    let locales: [String: String]          // "en" → "en-US"
    let shots: [Shot]
}

struct Shot: Decodable {
    let id: String
    let raw: [String: [String]]            // lang → one or two raw PNG paths (relative to shots.json)
    let headline: [String: String]
    let accentWord: [String: String]
    let accent: String                     // "coral" | "blue"
    let tilt: Double
}

// MARK: - Constants (spec: style B · Paper)

enum K {
    static let canvas = CGSize(width: 1320, height: 2868)
    static let paper = Color(red: 0xFB / 255, green: 0xF8 / 255, blue: 0xF1 / 255)
    static let rule = Color(red: 0xE7 / 255, green: 0xE1 / 255, blue: 0xD3 / 255)
    static let ink = Color(red: 0x2B / 255, green: 0x2B / 255, blue: 0x2B / 255)
    static let coral = NSColor(srgbRed: 1.0, green: 0x38 / 255, blue: 0x3C / 255, alpha: 1)
    static let blue = NSColor(srgbRed: 0, green: 0x88 / 255, blue: 1.0, alpha: 1)
    static let ruleSpacing: CGFloat = 76
    static let headlineTop: CGFloat = 190
    static let headlineWidth: CGFloat = 1140
    static let baseFontSize: CGFloat = 116
    static let minFontScale: CGFloat = 0.9
    static let phoneWidth: CGFloat = 990          // capture width on canvas
    static let phoneTop: CGFloat = 690
    static let bezel: CGFloat = 26
    static let screenCorner: CGFloat = 150        // iPhone 17 Pro Max display corner at this scale
}

// MARK: - Font

/// Apple's system serif (New York), semibold — always available on macOS,
/// so the pipeline needs no bundled font files.
func headlineFont(size: CGFloat) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: .semibold)
    guard let serif = base.fontDescriptor.withDesign(.serif),
          let font = NSFont(descriptor: serif, size: size) else { return base }
    return font
}

func attributed(_ text: String, accentWord: String, accent: NSColor, font: NSFont) -> NSAttributedString {
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineHeightMultiple = 1.02
    let s = NSMutableAttributedString(string: text, attributes: [
        .font: font, .foregroundColor: NSColor(K.ink), .paragraphStyle: para,
    ])
    if !accentWord.isEmpty, let r = text.range(of: accentWord) {
        s.addAttribute(.foregroundColor, value: accent, range: NSRange(r, in: text))
    }
    return s
}

func lineCount(_ s: NSAttributedString, width: CGFloat) -> Int {
    let storage = NSTextStorage(attributedString: s)
    let layout = NSLayoutManager()
    let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    container.lineFragmentPadding = 0
    layout.addTextContainer(container)
    storage.addLayoutManager(layout)
    var lines = 0, index = 0
    let glyphs = layout.numberOfGlyphs
    while index < glyphs {
        var range = NSRange()
        layout.lineFragmentRect(forGlyphAt: index, effectiveRange: &range)
        index = NSMaxRange(range)
        lines += 1
    }
    return lines
}

func lineWidth(_ text: String, font: NSFont) -> CGFloat {
    NSAttributedString(string: text, attributes: [.font: font]).size().width
}

/// Picks the layout: one line if it's comfortably short, otherwise the
/// two-line split (at a space, never inside the accent phrase, never at a
/// hyphen) whose longer line is shortest. Shrinks to ≥ 90 % of base size if
/// needed; nil if even that doesn't fit in two lines.
func fittingHeadline(_ text: String, accentWord: String, accent: NSColor) -> NSAttributedString? {
    let accentRange = text.range(of: accentWord)
    var size = K.baseFontSize
    while size >= K.baseFontSize * K.minFontScale - 0.01 {
        let font = headlineFont(size: size)
        if lineWidth(text, font: font) <= K.headlineWidth * 0.72 {
            return attributed(text, accentWord: accentWord, accent: accent, font: font)
        }
        var best: (text: String, width: CGFloat)?
        for idx in text.indices where text[idx] == " " {
            if let r = accentRange, r.contains(idx) { continue }
            let a = String(text[..<idx]), b = String(text[text.index(after: idx)...])
            let w = max(lineWidth(a, font: font), lineWidth(b, font: font))
            if w <= K.headlineWidth, w < (best?.width ?? .infinity) { best = (a + "\n" + b, w) }
        }
        if let best { return attributed(best.text, accentWord: accentWord, accent: accent, font: font) }
        size -= 2
    }
    return nil
}

/// Draws the headline with AppKit: SwiftUI `Text` re-resolves the font by name
/// and drops the variable-font weight.
func headlineImage(_ s: NSAttributedString) -> NSImage {
    let bounds = s.boundingRect(with: CGSize(width: K.headlineWidth, height: 2000),
                                options: [.usesLineFragmentOrigin, .usesFontLeading])
    let size = CGSize(width: K.headlineWidth, height: ceil(bounds.height))
    return NSImage(size: size, flipped: true) { rect in
        s.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
        return true
    }
}

// MARK: - Views

struct Paper: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(K.paper))
            var y: CGFloat = K.ruleSpacing * 1.5
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 3)), with: .color(K.rule))
                y += K.ruleSpacing
            }
        }
    }
}

struct Phone: View {
    let image: NSImage
    let width: CGFloat
    var body: some View {
        let h = width * image.size.height / image.size.width
        Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .frame(width: width, height: h)
            .clipShape(RoundedRectangle(cornerRadius: K.screenCorner * width / K.phoneWidth, style: .continuous))
            .padding(K.bezel * width / K.phoneWidth)
            .background(
                RoundedRectangle(cornerRadius: (K.screenCorner + K.bezel) * width / K.phoneWidth, style: .continuous)
                    .fill(Color(white: 0.09))
            )
            .overlay(
                RoundedRectangle(cornerRadius: (K.screenCorner + K.bezel) * width / K.phoneWidth, style: .continuous)
                    .strokeBorder(Color(white: 0.32), lineWidth: 4 * width / K.phoneWidth)
            )
            .shadow(color: .black.opacity(0.16), radius: 40, x: 18, y: 34)
    }
}

struct ShotView: View {
    let headline: NSAttributedString
    let images: [NSImage]
    let tilt: Double
    var body: some View {
        ZStack(alignment: .top) {
            Paper()
            Image(nsImage: headlineImage(headline))
                .padding(.top, K.headlineTop)
            if images.count == 1 {
                Phone(image: images[0], width: K.phoneWidth)
                    .rotationEffect(.degrees(tilt))
                    .padding(.top, K.phoneTop)
            } else {
                ZStack {
                    Phone(image: images[0], width: K.phoneWidth * 0.66)
                        .rotationEffect(.degrees(-abs(tilt) - 1.5))
                        .offset(x: -205, y: 0)
                    Phone(image: images[1], width: K.phoneWidth * 0.66)
                        .rotationEffect(.degrees(abs(tilt) + 1.5))
                        .offset(x: 205, y: 150)
                }
                .padding(.top, K.phoneTop + 40)
            }
        }
        .frame(width: K.canvas.width, height: K.canvas.height, alignment: .top)
        .clipped()
    }
}

// MARK: - Output

@MainActor
func render(_ view: some View, to url: URL) throws {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    renderer.proposedSize = ProposedViewSize(K.canvas)
    guard let cg = renderer.cgImage else { throw Failure("render failed") }
    // Flatten onto an opaque sRGB bitmap: App Store Connect rejects alpha.
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let ctx = CGContext(data: nil, width: Int(K.canvas.width), height: Int(K.canvas.height),
                              bitsPerComponent: 8, bytesPerRow: 0, space: space,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { throw Failure("context") }
    ctx.setFillColor(NSColor(K.paper).cgColor)
    ctx.fill(CGRect(origin: .zero, size: K.canvas))
    ctx.draw(cg, in: CGRect(origin: .zero, size: K.canvas))
    guard let flat = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { throw Failure("png") }
    CGImageDestinationAddImage(dest, flat, nil)
    guard CGImageDestinationFinalize(dest) else { throw Failure("write \(url.path)") }
}

struct Failure: Error, CustomStringConvertible {
    let description: String
    init(_ d: String) { description = d }
}

@main
struct Compose {
    @MainActor
    static func main() throws {
        let args = CommandLine.arguments
        guard args.count >= 3 else {
            print("usage: compose <shots.json> <outRoot> [--only <id>]"); exit(2)
        }
        let jsonURL = URL(fileURLWithPath: args[1]).absoluteURL.standardizedFileURL
        let base = jsonURL.deletingLastPathComponent()
        let outRoot = URL(fileURLWithPath: args[2], isDirectory: true)
        let only = args.count >= 5 && args[3] == "--only" ? args[4] : nil
        let file = try JSONDecoder().decode(ShotsFile.self, from: Data(contentsOf: jsonURL))

        var failures: [String] = []
        for shot in file.shots where only == nil || shot.id == only {
            for (lang, locale) in file.locales.sorted(by: { $0.key < $1.key }) {
                guard let text = shot.headline[lang], let paths = shot.raw[lang] else {
                    failures.append("\(shot.id)/\(lang): missing headline or raw"); continue
                }
                let accent = shot.accent == "blue" ? K.blue : K.coral
                guard let headline = fittingHeadline(text, accentWord: shot.accentWord[lang] ?? "", accent: accent) else {
                    failures.append("\(shot.id)/\(lang): headline needs > 2 lines at ≥ 90 %: \(text)"); continue
                }
                let images = try paths.map { p -> NSImage in
                    guard let img = NSImage(contentsOf: base.appendingPathComponent(p)) else { throw Failure("missing raw \(p)") }
                    return img
                }
                let dir = outRoot.appendingPathComponent(locale, isDirectory: true)
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let url = dir.appendingPathComponent("\(shot.id).png")
                try render(ShotView(headline: headline, images: images, tilt: shot.tilt), to: url)
                print("wrote \(locale)/\(shot.id).png")
            }
        }
        if !failures.isEmpty {
            failures.forEach { print("FAIL \($0)") }
            exit(1)
        }
    }
}
