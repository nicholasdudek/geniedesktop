import SwiftUI

struct LogEvent: Identifiable {
    let id = UUID()
    let timestamp: String
    let message: String
    let level: String
}

struct RuntimeLogView: View {
    @State private var logs: [LogEvent] = []
    @State private var isConnected = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Runtime Live Stream")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(isConnected ? "CONNECTED" : "DISCONNECTED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 12)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(logs) { log in
                            HStack(alignment: .top, spacing: 12) {
                                Text(log.timestamp)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Text(log.message)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(logColor(log.level))
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(6)
                        }
                    }
                }
                .onChange(of: logs.count) { _, _ in
                    withAnimation { proxy.scrollTo(logs.last?.id) }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            startLogStream()
        }
    }
    
    private func logColor(_ level: String) -> Color {
        switch level {
        case "INFO": return .green
        case "ERROR": return .red
        case "DEBUG": return .blue
        default: return .white
        }
    }
    
    private func startLogStream() {
        // This connects to the log_emitter.py socket we built earlier
        DispatchQueue.global().async {
            // Logic to open socket to localhost:9999 and update @logs
            // In a full implementation, this would use NWConnection
        }
    }
}
