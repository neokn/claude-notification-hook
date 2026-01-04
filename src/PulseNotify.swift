#!/usr/bin/env swift

import Cocoa
import SwiftUI

// MARK: - Configuration
struct NotifyConfig {
    let color: NSColor
    let duration: Double
    let breathCycle: Double
    let minBrightness: Double
    let maxBrightness: Double
    let inhaleSigma: Double
    let exhaleSigma: Double
    let minGlowHeight: CGFloat
    let maxGlowHeight: CGFloat
    let minGlowWidth: CGFloat
    let maxGlowWidth: CGFloat
    let minBlurRadius: CGFloat
    let maxBlurRadius: CGFloat
    let soundName: String?

    static func from(args: [String]) -> NotifyConfig {
        var color: NSColor = .systemOrange
        var duration: Double = 8.0
        var breathCycle: Double = 4.0
        var minBrightness: Double = 0.15
        var maxBrightness: Double = 1.0
        var inhaleSigma: Double = 0.8
        var exhaleSigma: Double = 1.2
        var minGlowHeight: CGFloat = 80
        var maxGlowHeight: CGFloat = 160
        var minGlowWidth: CGFloat = 100
        var maxGlowWidth: CGFloat = 200
        var minBlurRadius: CGFloat = 20
        var maxBlurRadius: CGFloat = 45
        var soundName: String? = "Ping"

        for (index, arg) in args.enumerated() {
            switch arg {
            case "--color", "-c":
                if index + 1 < args.count {
                    let colorValue = args[index + 1]
                    if colorValue.hasPrefix("#") || colorValue.count == 6 {
                        if let hexColor = NSColor.fromHex(colorValue) { color = hexColor }
                    } else {
                        switch colorValue.lowercased() {
                        case "green": color = .systemGreen
                        case "orange": color = .systemOrange
                        case "blue": color = .systemBlue
                        case "red": color = .systemRed
                        case "purple": color = .systemPurple
                        case "yellow": color = .systemYellow
                        case "pink": color = .systemPink
                        case "cyan": color = .cyan
                        case "white": color = .white
                        default: break
                        }
                    }
                }
            case "--duration", "-d":
                if index + 1 < args.count { duration = Double(args[index + 1]) ?? 8.0 }
            case "--breath-cycle":
                if index + 1 < args.count { breathCycle = Double(args[index + 1]) ?? 4.0 }
            case "--min-brightness":
                if index + 1 < args.count { minBrightness = Double(args[index + 1]) ?? 0.15 }
            case "--max-brightness":
                if index + 1 < args.count { maxBrightness = Double(args[index + 1]) ?? 1.0 }
            case "--inhale-sigma":
                if index + 1 < args.count { inhaleSigma = Double(args[index + 1]) ?? 0.8 }
            case "--exhale-sigma":
                if index + 1 < args.count { exhaleSigma = Double(args[index + 1]) ?? 1.2 }
            case "--min-glow-height":
                if index + 1 < args.count { minGlowHeight = CGFloat(Double(args[index + 1]) ?? 80) }
            case "--max-glow-height":
                if index + 1 < args.count { maxGlowHeight = CGFloat(Double(args[index + 1]) ?? 160) }
            case "--min-glow-width":
                if index + 1 < args.count { minGlowWidth = CGFloat(Double(args[index + 1]) ?? 100) }
            case "--max-glow-width":
                if index + 1 < args.count { maxGlowWidth = CGFloat(Double(args[index + 1]) ?? 200) }
            case "--min-blur":
                if index + 1 < args.count { minBlurRadius = CGFloat(Double(args[index + 1]) ?? 20) }
            case "--max-blur":
                if index + 1 < args.count { maxBlurRadius = CGFloat(Double(args[index + 1]) ?? 45) }
            case "--sound", "-s":
                if index + 1 < args.count { soundName = args[index + 1] }
            case "--no-sound":
                soundName = nil
            default: break
            }
        }

        return NotifyConfig(
            color: color, duration: duration, breathCycle: breathCycle,
            minBrightness: minBrightness, maxBrightness: maxBrightness,
            inhaleSigma: inhaleSigma, exhaleSigma: exhaleSigma,
            minGlowHeight: minGlowHeight, maxGlowHeight: maxGlowHeight,
            minGlowWidth: minGlowWidth, maxGlowWidth: maxGlowWidth,
            minBlurRadius: minBlurRadius, maxBlurRadius: maxBlurRadius,
            soundName: soundName
        )
    }

    func playSound() {
        guard let name = soundName else { return }
        if let sound = NSSound(contentsOfFile: "/System/Library/Sounds/\(name).aiff", byReference: true) {
            sound.play()
        }
    }
}

extension NSColor {
    static func fromHex(_ hex: String) -> NSColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let length = hexSanitized.count
        if length == 6 {
            let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(rgb & 0x0000FF) / 255.0
            return NSColor(red: r, green: g, blue: b, alpha: 1.0)
        } else if length == 8 {
            let r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            let g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            let b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            let a = CGFloat(rgb & 0x000000FF) / 255.0
            return NSColor(red: r, green: g, blue: b, alpha: a)
        }
        return nil
    }
}

struct PulseOverlayView: View {
    let config: NotifyConfig
    @State private var opacity: Double = 0
    @State private var glowScale: Double = 0
    @State private var timer: Timer?
    @State private var startTime: Date?

    private var currentGlowHeight: CGFloat {
        config.minGlowHeight + CGFloat(glowScale) * (config.maxGlowHeight - config.minGlowHeight)
    }
    private var currentGlowWidth: CGFloat {
        config.minGlowWidth + CGFloat(glowScale) * (config.maxGlowWidth - config.minGlowWidth)
    }
    private var currentBlurRadius: CGFloat {
        config.minBlurRadius + CGFloat(glowScale) * (config.maxBlurRadius - config.minBlurRadius)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                VStack {
                    LinearGradient(colors: [Color(config.color).opacity(0.8), Color(config.color).opacity(0.3), Color.clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: currentGlowHeight).blur(radius: currentBlurRadius)
                    Spacer()
                }
                VStack {
                    Spacer()
                    LinearGradient(colors: [Color.clear, Color(config.color).opacity(0.3), Color(config.color).opacity(0.8)], startPoint: .top, endPoint: .bottom)
                        .frame(height: currentGlowHeight).blur(radius: currentBlurRadius)
                }
                HStack {
                    LinearGradient(colors: [Color(config.color).opacity(0.8), Color(config.color).opacity(0.3), Color.clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: currentGlowWidth).blur(radius: currentBlurRadius)
                    Spacer()
                }
                HStack {
                    Spacer()
                    LinearGradient(colors: [Color.clear, Color(config.color).opacity(0.3), Color(config.color).opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        .frame(width: currentGlowWidth).blur(radius: currentBlurRadius)
                }
            }
            .opacity(opacity)
        }
        .ignoresSafeArea()
        .onAppear {
            config.playSound()
            startBreathingAnimation()
        }
    }

    private func startBreathingAnimation() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            guard let startTime = self.startTime else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= config.duration {
                self.timer?.invalidate()
                self.timer = nil
                withAnimation(.easeOut(duration: 0.3)) {
                    self.opacity = 0
                    self.glowScale = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApplication.shared.terminate(nil)
                }
                return
            }
            let (brightness, scale) = calculateGaussianBreathing(elapsed: elapsed)
            self.opacity = brightness
            self.glowScale = scale
        }
    }

    private func calculateGaussianBreathing(elapsed: Double) -> (Double, Double) {
        let t = elapsed.truncatingRemainder(dividingBy: config.breathCycle)
        let halfCycle = config.breathCycle / 2.0
        var gaussian: Double
        if t < halfCycle {
            let x = (t / halfCycle) * 2.0 - 1.0
            gaussian = exp(-x * x / (2.0 * config.inhaleSigma * config.inhaleSigma))
        } else {
            let x = ((t - halfCycle) / halfCycle) * 2.0 - 1.0
            gaussian = exp(-x * x / (2.0 * config.exhaleSigma * config.exhaleSigma))
        }
        let brightness = config.minBrightness + (config.maxBrightness - config.minBrightness) * gaussian
        return (max(config.minBrightness, min(config.maxBrightness, brightness)), max(0, min(1, gaussian)))
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let config: NotifyConfig

    init(config: NotifyConfig) {
        self.config = config
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else {
            NSApplication.shared.terminate(nil)
            return
        }
        window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = NSHostingView(rootView: PulseOverlayView(config: config))
        window.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.accessory)
    }
}

let config = NotifyConfig.from(args: Array(CommandLine.arguments.dropFirst()))
let delegate = AppDelegate(config: config)
let app = NSApplication.shared
app.delegate = delegate
app.run()
