import Foundation
import SwiftUI

/// High-efficiency digital matrix rain effect module for Genie.
/// Can be invoked directly from terminal or embedded within Genie developer views.
public struct TerminalMatrixRain {
    public static let characters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()_+{}|:<>?~")

    public static func runInteractive(width: Int = 100, height: Int = 30) {
        var columns = [Int](repeating: 0, count: width)
        print("\u{1B}[?25l\u{1B}[2J\u{1B}[1m", terminator: "") // Hide cursor, clear screen

        signal(SIGINT) { _ in
            print("\u{1B}[?25h\u{1B}[0m\u{1B}[2J\u{1B}[H")
            exit(0)
        }

        while true {
            var buffer = "\u{1B}[H"
            for _ in 0..<height {
                for x in 0..<width {
                    if Int.random(in: 0..<100) < 3 && columns[x] <= 0 {
                        columns[x] = Int.random(in: 5...height + 10)
                    }

                    if columns[x] > 0 {
                        let color = columns[x] == 1 ? "\u{1B}[97m" : (columns[x] > 15 ? "\u{1B}[32m" : "\u{1B}[92m")
                        let char = characters.randomElement() ?? "1"
                        buffer.append("\(color)\(char)")
                        columns[x] -= 1
                    } else {
                        buffer.append(" ")
                    }
                }
                buffer.append("\n")
            }
            print(buffer, terminator: "")
            fflush(stdout)
            usleep(70_000)
        }
    }
}
