import SwiftUI

public struct PillowEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorldClockViewModel
    @State private var pillow: PillowClock
    @State private var customLabelText: String = ""
    
    public init(viewModel: WorldClockViewModel, pillow: PillowClock) {
        self.viewModel = viewModel
        self._pillow = State(initialValue: pillow)
        self._customLabelText = State(initialValue: pillow.customLabel ?? "")
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Form {
                    // Preview Section
                    Section {
                        PillowCardView(
                            pillow: pillow,
                            date: viewModel.effectiveDate,
                            localTimeZone: viewModel.localTimeZone
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    } header: {
                        Text("Live Preview").foregroundColor(.gray)
                    }
                    
                    // City & Nickname
                    Section {
                        HStack {
                            Text("City")
                            Spacer()
                            Text(pillow.cityName)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Timezone")
                            Spacer()
                            Text(pillow.timeZoneIdentifier)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        
                        TextField("Custom Nickname (e.g. Grandma, London Office)", text: $customLabelText)
                            .onChange(of: customLabelText) { newVal in
                                pillow.customLabel = newVal.isEmpty ? nil : newVal
                            }
                    } header: {
                        Text("Location Details").foregroundColor(.gray)
                    }
                    .listRowBackground(Color(red: 0.1, green: 0.1, blue: 0.12))
                    
                    // Pillow Sizing
                    Section {
                        Picker("Card Size", selection: $pillow.size) {
                            ForEach(PillowSize.allCases) { sz in
                                Text(sz.rawValue).tag(sz)
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Pillow Size & Scale").foregroundColor(.gray)
                    } footer: {
                        Text("Adjustable from compact slim pill to large expanded stand-by clock.")
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(red: 0.1, green: 0.1, blue: 0.12))
                    
                    // Accent Color Glow
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(PillowAccent.allCases) { accent in
                                    Button {
                                        pillow.accent = accent
                                    } label: {
                                        VStack(spacing: 6) {
                                            Circle()
                                                .fill(accent.color)
                                                .frame(width: 36, height: 36)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: pillow.accent == accent ? 3 : 0)
                                                )
                                                .shadow(color: accent.color.opacity(0.6), radius: pillow.accent == accent ? 8 : 0)
                                            
                                            Text(accent.rawValue)
                                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                                .foregroundColor(pillow.accent == accent ? .white : .gray)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    } header: {
                        Text("Glow & Dial Accent Color").foregroundColor(.gray)
                    }
                    .listRowBackground(Color(red: 0.1, green: 0.1, blue: 0.12))
                    
                    // Display Options
                    Section {
                        Toggle("Show Analog Clock Dial", isOn: $pillow.showAnalogDial)
                        Toggle("Show Live Seconds Hand", isOn: $pillow.showSeconds)
                        Toggle("Show Sun / Moon Day Indicator", isOn: $pillow.showDayNightIndicator)
                    } header: {
                        Text("Visual Preferences").foregroundColor(.gray)
                    }
                    .listRowBackground(Color(red: 0.1, green: 0.1, blue: 0.12))
                    
                    // Delete Pillow
                    Section {
                        Button(role: .destructive) {
                            viewModel.removePillow(id: pillow.id)
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete this Pillow", systemImage: "trash.fill")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                    .listRowBackground(Color(red: 0.15, green: 0.05, blue: 0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Customize Pillow")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.updatePillow(pillow)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
