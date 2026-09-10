//
//  DesktopPartitionMenuBarView.swift
//  GoldGate
//
//  Created for Genie Quantum 2028 Architecture.
//  Renders dedicated macOS MenuBars for independent desktop partitions
//  and hosts the full dual-partition workspace canvas.
//

import SwiftUI
import AppKit

// MARK: - Dedicated Partition MenuBar View

@MainActor
public struct DesktopPartitionMenuBarView: View {
    public let partition: DesktopPartition
    @ObservedObject public var partitionManager: DualDesktopPartitionManager
    
    @State private var hoveredMenu: String? = nil
    
    @MainActor
    public init(partition: DesktopPartition, partitionManager: DualDesktopPartitionManager? = nil) {
        self.partition = partition
        self.partitionManager = partitionManager ?? .shared
    }
    
    private var themeColor: Color {
        Color(hex: partition.themeColorHex)
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // 1. Apple Logo & Partition Badge
            HStack(spacing: 6) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                
                Text(partition.partitionIndex == 0 ? "DESKTOP 1" : "DESKTOP 2")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(themeColor.opacity(0.25))
                    .foregroundColor(themeColor)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(themeColor.opacity(0.5), lineWidth: 0.5)
                    )
            }
            .padding(.leading, 12)
            
            // 2. Active App Name (Bold)
            Text(partition.activeAppName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // 3. Dynamic Application Menus
            HStack(spacing: 10) {
                ForEach(partition.menuBarTitles.prefix(6), id: \.self) { title in
                    Text(title)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(hoveredMenu == title ? .white : .white.opacity(0.80))
                        .padding(.horizontal, 3)
                        .padding(.vertical, 2)
                        .background(hoveredMenu == title ? Color.white.opacity(0.12) : Color.clear)
                        .cornerRadius(4)
                        .onHover { isHovered in
                            hoveredMenu = isHovered ? title : nil
                        }
                }
            }
            
            Spacer(minLength: 10)
            
            // 4. Dedicated Agent Status Pill
            HStack(spacing: 5) {
                Circle()
                    .fill(partitionManager.isSimultaneousInputting ? Color.yellow : themeColor)
                    .frame(width: 6, height: 6)
                
                Text(partition.agentName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.4))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeColor.opacity(0.4), lineWidth: 0.8)
            )
            
            // 5. Partition Local Time
            Text(Date(), style: .time)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))
                .padding(.trailing, 12)
        }
        .frame(height: 28)
        .background(
            ZStack {
                Color(red: 0.07, green: 0.08, blue: 0.12).opacity(0.88)
                LinearGradient(
                    colors: [themeColor.opacity(0.12), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.15)),
            alignment: .bottom
        )
    }
}

// MARK: - Dual Desktop Partition Canvas View

@MainActor
public struct DualDesktopPartitionCanvasView: View {
    @ObservedObject public var manager: DualDesktopPartitionManager = .shared
    
    @State private var inputTestTextA: String = "const kernel = new MetalKernel();"
    @State private var inputTestTextB: String = "https://developer.apple.com/documentation"
    @State private var isSimulating: Bool = false
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let totalW = geo.size.width
            let widthA = totalW * manager.splitRatio
            let widthB = totalW - widthA
            
            ZStack(alignment: .topLeading) {
                // Background Desktop Base
                Color.black.edgesIgnoringSafeArea(.all)
                
                HStack(spacing: 0) {
                    // ==========================================
                    // DESKTOP 1: LEFT PARTITION WITH OWN MENUBAR
                    // ==========================================
                    VStack(spacing: 0) {
                        // Desktop 1 Dedicated MenuBar
                        DesktopPartitionMenuBarView(partition: manager.partitionA, partitionManager: manager)
                        
                        // Desktop 1 Workspace Canvas Area
                        ZStack {
                            LinearGradient(
                                colors: [Color(red: 0.05, green: 0.07, blue: 0.12), Color(red: 0.03, green: 0.04, blue: 0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            VStack(spacing: 16) {
                                Image(systemName: "curlybraces.square.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: manager.partitionA.themeColorHex).opacity(0.8))
                                
                                Text(manager.partitionA.activeAppName)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Independent Desktop Canvas 1")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                // Interactive Simultaneous Input Target Field A
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Simultaneous Input Receiver A:")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color(hex: manager.partitionA.themeColorHex))
                                    
                                    TextField("Target Field A...", text: $inputTestTextA)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(8)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color(hex: manager.partitionA.themeColorHex).opacity(0.5), lineWidth: 1)
                                        )
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: 320)
                            }
                            .padding(24)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: widthA)
                    .clipped()
                    
                    // ==========================================
                    // INTERACTIVE DRAGGABLE PARTITION DIVIDER
                    // ==========================================
                    ZStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 4)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .shadow(radius: 4)
                    }
                    .frame(width: 14)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { val in
                                let newRatio = (widthA + val.translation.width) / totalW
                                manager.setSplitRatio(newRatio)
                            }
                    )
                    
                    // ==========================================
                    // DESKTOP 2: RIGHT PARTITION WITH OWN MENUBAR
                    // ==========================================
                    VStack(spacing: 0) {
                        // Desktop 2 Dedicated MenuBar
                        DesktopPartitionMenuBarView(partition: manager.partitionB, partitionManager: manager)
                        
                        // Desktop 2 Workspace Canvas Area
                        ZStack {
                            LinearGradient(
                                colors: [Color(red: 0.04, green: 0.09, blue: 0.08), Color(red: 0.02, green: 0.05, blue: 0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            VStack(spacing: 16) {
                                Image(systemName: "safari.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: manager.partitionB.themeColorHex).opacity(0.8))
                                
                                Text(manager.partitionB.activeAppName)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Independent Desktop Canvas 2")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                // Interactive Simultaneous Input Target Field B
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Simultaneous Input Receiver B:")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color(hex: manager.partitionB.themeColorHex))
                                    
                                    TextField("Target Field B...", text: $inputTestTextB)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(8)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color(hex: manager.partitionB.themeColorHex).opacity(0.5), lineWidth: 1)
                                        )
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: 320)
                            }
                            .padding(24)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: widthB - 14)
                    .clipped()
                }
                
                // ==========================================
                // BOTTOM FLOATING HUD: SIMULTANEOUS ACTION BAR
                // ==========================================
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SIMULTANEOUS DUAL-AGENT ENGINE")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundColor(.yellow)
                                Text(manager.lastSimultaneousInputSummary)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                            }
                            
                            Button(action: {
                                Task {
                                    let inputA = PartitionFieldInput(partitionIndex: 0, targetText: inputTestTextA, pressReturnAfter: true)
                                    let inputB = PartitionFieldInput(partitionIndex: 1, targetText: inputTestTextB, pressReturnAfter: true)
                                    await manager.executeSimultaneousFieldInputs(inputA: inputA, inputB: inputB)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "bolt.horizontal.fill")
                                    Text("Trigger Simultaneous Inputs")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.yellow)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(red: 0.08, green: 0.09, blue: 0.14).opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                        )
                        .shadow(radius: 12)
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

// MARK: - Dedicated Panel Window

@MainActor
public final class DualDesktopPartitionWindow {
    public static let shared = DualDesktopPartitionWindow()
    private var window: NSPanel?
    
    private init() {}
    
    public func show() {
        if window == nil {
            let panel = NSPanel(
                contentRect: NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: DualDesktopPartitionCanvasView())
            window = panel
        }
        window?.makeKeyAndOrderFront(nil)
    }
    
    public func close() {
        window?.orderOut(nil)
        window = nil
    }
}
