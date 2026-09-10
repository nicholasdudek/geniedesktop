import AppKit
import Foundation
import SwiftUI

// MARK: - Premium Apple-Grade Terminal & LeetCode Cookbook Command Center
// Combines an interactive high-performance zsh terminal with full developer menus,
// a complete LeetCode algorithm cookbook suite, and 1-click free local AI model installation.

public struct LeetCodeRecipe: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let difficulty: String // "Easy", "Medium", "Hard"
    public let category: String
    public let timeComplexity: String
    public let spaceComplexity: String
    public let promptSummary: String
    public let swiftSolution: String
    public let pythonSolution: String
    public let testRunnerCommand: String

    public var difficultyColor: Color {
        switch difficulty.lowercased() {
        case "easy": return .green
        case "medium": return .orange
        case "hard": return .red
        default: return .cyan
        }
    }
}

public struct GeniePremiumTerminalCookbookView: View {
    @ObservedObject var tinyEngine: GenieLocalTinyModelEngine = .shared
    @ObservedObject var localModels: LocalModelManager = .shared

    @State private var terminalInput: String = ""
    @State private var terminalOutput: String = """
Genie Pro Terminal & Algorithm Command Center v2.0 (macOS zsh)
Type any shell directive, or choose a LeetCode algorithm from the cookbook below.
--------------------------------------------------------------------------------
"""
    @State private var isRunningCommand: Bool = false
    @State private var selectedCookbookCategory: String = "All"
    @State private var selectedRecipe: LeetCodeRecipe? = nil
    @State private var showModelHubDrawer: Bool = false
    @State private var showCookbookDrawer: Bool = true
    @State private var toastNotification: String? = nil
    @FocusState private var isTerminalFocused: Bool

    // ── LeetCode Algorithm Recipes ──────────────────────────────────────────
    private let leetCodeCookbooks: [LeetCodeRecipe] = [
        LeetCodeRecipe(
            id: "two_sum",
            title: "1. Two Sum",
            difficulty: "Easy",
            category: "Arrays & Hash Map",
            timeComplexity: "O(n)",
            spaceComplexity: "O(n)",
            promptSummary: "Find two numbers in an array that sum to target.",
            swiftSolution: """
func twoSum(_ nums: [Int], _ target: Int) -> [Int] {
    var dict = [Int: Int]() // value -> index
    for (i, num) in nums.enumerated() {
        if let complementIndex = dict[target - num] {
            return [complementIndex, i]
        }
        dict[num] = i
    }
    return []
}
""",
            pythonSolution: """
def two_sum(nums, target):
    seen = {}
    for i, num in enumerate(nums):
        complement = target - num
        if complement in seen:
            return [seen[complement], i]
        seen[num] = i
    return []

# Test execution
print("Two Sum Result:", two_sum([2, 7, 11, 15], 9)) # [0, 1]
""",
            testRunnerCommand: "python3 -c 'seen={}; nums=[2,7,11,15]; target=9; print(\"Two Sum Solution:\", [(seen[target-x], i) for i, x in enumerate(nums) if (target-x in seen) or seen.update({x: i})])'"
        ),
        LeetCodeRecipe(
            id: "longest_substring",
            title: "3. Longest Substring Without Repeating Characters",
            difficulty: "Medium",
            category: "Sliding Window",
            timeComplexity: "O(n)",
            spaceComplexity: "O(min(n, m))",
            promptSummary: "Find the length of the longest substring with all unique characters.",
            swiftSolution: """
func lengthOfLongestSubstring(_ s: String) -> Int {
    var charMap = [Character: Int]()
    var maxLen = 0, left = 0
    let chars = Array(s)
    for (right, char) in chars.enumerated() {
        if let lastSeen = charMap[char], lastSeen >= left {
            left = lastSeen + 1
        }
        charMap[char] = right
        maxLen = max(maxLen, right - left + 1)
    }
    return maxLen
}
""",
            pythonSolution: """
def length_of_longest_substring(s: str) -> int:
    char_map = {}
    max_len = left = 0
    for right, char in enumerate(s):
        if char in char_map and char_map[char] >= left:
            left = char_map[char] + 1
        char_map[char] = right
        max_len = max(max_len, right - left + 1)
    return max_len

print("Longest Substring Len:", length_of_longest_substring("abcabcbb")) # 3
""",
            testRunnerCommand: "python3 -c 's=\"abcabcbb\"; m={}; l=ans=0\nfor r, c in enumerate(s):\n if c in m and m[c]>=l: l=m[c]+1\n m[c]=r; ans=max(ans, r-l+1)\nprint(\"Max Substring Length for abcabcbb:\", ans)'"
        ),
        LeetCodeRecipe(
            id: "trapping_water",
            title: "42. Trapping Rain Water",
            difficulty: "Hard",
            category: "Two Pointers",
            timeComplexity: "O(n)",
            spaceComplexity: "O(1)",
            promptSummary: "Compute how much water elevation map can trap after raining.",
            swiftSolution: """
func trap(_ height: [Int]) -> Int {
    guard height.count > 2 else { return 0 }
    var left = 0, right = height.count - 1
    var leftMax = 0, rightMax = 0, total = 0
    while left < right {
        if height[left] < height[right] {
            if height[left] >= leftMax { leftMax = height[left] }
            else { total += leftMax - height[left] }
            left += 1
        } else {
            if height[right] >= rightMax { rightMax = height[right] }
            else { total += rightMax - height[right] }
            right -= 1
        }
    }
    return total
}
""",
            pythonSolution: """
def trap(height):
    left, right = 0, len(height) - 1
    left_max = right_max = total = 0
    while left < right:
        if height[left] < height[right]:
            if height[left] >= left_max: left_max = height[left]
            else: total += left_max - height[left]
            left += 1
        else:
            if height[right] >= right_max: right_max = height[right]
            else: total += right_max - height[right]
            right -= 1
    return total

print("Trapped Water:", trap([0,1,0,2,1,0,1,3,2,1,2,1])) # 6
""",
            testRunnerCommand: "python3 -c 'h=[0,1,0,2,1,0,1,3,2,1,2,1]; l,r=0,len(h)-1; lm=rm=tot=0\nwhile l<r:\n if h[l]<h[r]:\n  if h[l]>=lm: lm=h[l]\n  else: tot+=lm-h[l]\n  l+=1\n else:\n  if h[r]>=rm: rm=h[r]\n  else: tot+=rm-h[r]\n  r-=1\nprint(\"Trapped Rain Water Units:\", tot)'"
        ),
        LeetCodeRecipe(
            id: "num_islands",
            title: "200. Number of Islands",
            difficulty: "Medium",
            category: "Graphs & Grid BFS/DFS",
            timeComplexity: "O(m * n)",
            spaceComplexity: "O(m * n)",
            promptSummary: "Count the number of islands ('1's surrounded by '0' water).",
            swiftSolution: """
func numIslands(_ grid: [[Character]]) -> Int {
    var g = grid
    guard !g.isEmpty else { return 0 }
    let rows = g.count, cols = g[0].count
    var count = 0

    func dfs(_ r: Int, _ c: Int) {
        guard r >= 0 && r < rows && c >= 0 && c < cols && g[r][c] == "1" else { return }
        g[r][c] = "0" // mark visited
        dfs(r + 1, c); dfs(r - 1, c); dfs(r, c + 1); dfs(r, c - 1)
    }

    for r in 0..<rows {
        for c in 0..<cols where g[r][c] == "1" {
            count += 1
            dfs(r, c)
        }
    }
    return count
}
""",
            pythonSolution: """
def num_islands(grid):
    if not grid: return 0
    rows, cols = len(grid), len(grid[0])
    count = 0

    def dfs(r, c):
        if 0 <= r < rows and 0 <= c < cols and grid[r][c] == '1':
            grid[r][c] = '0'
            dfs(r+1, c); dfs(r-1, c); dfs(r, c+1); dfs(r, c-1)

    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == '1':
                count += 1
                dfs(r, c)
    return count

grid = [['1','1','0'],['1','1','0'],['0','0','1']]
print("Number of Islands:", num_islands(grid)) # 2
""",
            testRunnerCommand: "python3 -c 'g=[[\"1\",\"1\",\"0\"],[\"1\",\"1\",\"0\"],[\"0\",\"0\",\"1\"]]; r,c=len(g),len(g[0]); cnt=0\ndef dfs(i,j):\n if 0<=i<r and 0<=j<c and g[i][j]==\"1\": g[i][j]=\"0\"; dfs(i+1,j); dfs(i-1,j); dfs(i,j+1); dfs(i,j-1)\nfor i in range(r):\n for j in range(c):\n  if g[i][j]==\"1\": cnt+=1; dfs(i,j)\nprint(\"Number of Islands in 3x3 Grid:\", cnt)'"
        ),
        LeetCodeRecipe(
            id: "coin_change",
            title: "322. Coin Change",
            difficulty: "Medium",
            category: "Dynamic Programming",
            timeComplexity: "O(amount * coins)",
            spaceComplexity: "O(amount)",
            promptSummary: "Find fewest coins needed to make up a given amount.",
            swiftSolution: """
func coinChange(_ coins: [Int], _ amount: Int) -> Int {
    guard amount > 0 else { return 0 }
    var dp = Array(repeating: amount + 1, count: amount + 1)
    dp[0] = 0
    for a in 1...amount {
        for coin in coins where a - coin >= 0 {
            dp[a] = min(dp[a], 1 + dp[a - coin])
        }
    }
    return dp[amount] > amount ? -1 : dp[amount]
}
""",
            pythonSolution: """
def coin_change(coins, amount):
    dp = [float('inf')] * (amount + 1)
    dp[0] = 0
    for a in range(1, amount + 1):
        for c in coins:
            if a - c >= 0:
                dp[a] = min(dp[a], 1 + dp[a - c])
    return dp[amount] if dp[amount] != float('inf') else -1

print("Fewest Coins for Amount 11 with [1,2,5]:", coin_change([1,2,5], 11)) # 3
""",
            testRunnerCommand: "python3 -c 'coins=[1,2,5]; amount=11; dp=[float(\"inf\")]*(amount+1); dp[0]=0\nfor a in range(1,amount+1):\n for c in coins:\n  if a-c>=0: dp[a]=min(dp[a], 1+dp[a-c])\nprint(\"Coin Change (11 from [1,2,5]):\", dp[amount], \"coins\")'"
        ),
        LeetCodeRecipe(
            id: "binary_search_rotated",
            title: "33. Search in Rotated Sorted Array",
            difficulty: "Medium",
            category: "Binary Search",
            timeComplexity: "O(log n)",
            spaceComplexity: "O(1)",
            promptSummary: "Find index of target in sorted array rotated at pivot.",
            swiftSolution: """
func search(_ nums: [Int], _ target: Int) -> Int {
    var left = 0, right = nums.count - 1
    while left <= right {
        let mid = left + (right - left) / 2
        if nums[mid] == target { return mid }
        if nums[left] <= nums[mid] {
            if nums[left] <= target && target < nums[mid] { right = mid - 1 }
            else { left = mid + 1 }
        } else {
            if nums[mid] < target && target <= nums[right] { left = mid + 1 }
            else { right = mid - 1 }
        }
    }
    return -1
}
""",
            pythonSolution: """
def search_rotated(nums, target):
    l, r = 0, len(nums) - 1
    while l <= r:
        m = (l + r) // 2
        if nums[m] == target: return m
        if nums[l] <= nums[m]:
            if nums[l] <= target < nums[m]: r = m - 1
            else: l = m + 1
        else:
            if nums[m] < target <= nums[r]: l = m + 1
            else: r = m - 1
    return -1

print("Rotated Index of 0 in [4,5,6,7,0,1,2]:", search_rotated([4,5,6,7,0,1,2], 0)) # 4
""",
            testRunnerCommand: "python3 -c 'nums=[4,5,6,7,0,1,2]; t=0; l,r=0,len(nums)-1\nwhile l<=r:\n m=(l+r)//2\n if nums[m]==t: print(\"Found at index:\", m); break\n if nums[l]<=nums[m]:\n  if nums[l]<=t<nums[m]: r=m-1\n  else: l=m+1\n else:\n  if nums[m]<t<=nums[r]: l=m+1\n  else: r=m-1'"
        )
    ]

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - 1. Top Command Center Toolbar & Actions
            terminalTopToolbar

            Divider().opacity(0.35)

            // MARK: - 2. Quick Menus & Diagnostics Bar
            quickDiagnosticsMenuBar

            Divider().opacity(0.35)

            // MARK: - 3. Free Local AI Models 1-Click Installer Drawer (Expandable)
            if showModelHubDrawer {
                freeModelHubDrawer
                    .transition(.move(edge: .top).combined(with: .opacity))
                Divider().opacity(0.35)
            }

            // MARK: - 4. Main Body: Split Terminal Screen + LeetCode Cookbooks
            HStack(spacing: 0) {
                // Left Pane: High-Performance Terminal Console
                VStack(spacing: 0) {
                    terminalConsoleScreen
                    terminalCommandPromptBar
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Right Pane: LeetCode Cookbook Suite
                if showCookbookDrawer {
                    Divider().opacity(0.35)

                    leetCodeCookbookSidebar
                        .frame(width: 320)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .background(Color(red: 0.06, green: 0.08, blue: 0.12).opacity(0.98))
        .overlay(alignment: .top) {
            if let toast = toastNotification {
                Text(toast)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.green.opacity(0.95)))
                    .shadow(color: Color.green.opacity(0.4), radius: 8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - 1. Top Command Center Toolbar
    private var terminalTopToolbar: some View {
        HStack(spacing: 10) {
            // Traffic Light Clearance
            HStack(spacing: 5) {
                Circle().fill(Color.red.opacity(0.85)).frame(width: 10, height: 10)
                Circle().fill(Color.yellow.opacity(0.85)).frame(width: 10, height: 10)
                Circle().fill(Color.green.opacity(0.85)).frame(width: 10, height: 10)
            }

            Text("zsh — developer terminal")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            // 1-Click Free Local Model Hub Toggle
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    showModelHubDrawer.toggle()
                }
                HapticFeedback.selection()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.cyan)
                    Text("Free Local Models Hub")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.cyan.opacity(showModelHubDrawer ? 0.28 : 0.12)))
                .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 0.8))
            }
            .buttonStyle(.plain)

            // LeetCode Cookbook Drawer Toggle
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    showCookbookDrawer.toggle()
                }
                HapticFeedback.selection()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(.yellow)
                    Text("LeetCode Cookbooks")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.yellow.opacity(showCookbookDrawer ? 0.28 : 0.12)))
                .overlay(Capsule().stroke(Color.yellow.opacity(0.35), lineWidth: 0.8))
            }
            .buttonStyle(.plain)

            // Clear Terminal Buffer
            Button(action: {
                terminalOutput = ""
                HapticFeedback.tick()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help("Clear Buffer")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.45))
    }

    // MARK: - 2. Quick Menus & Diagnostics Bar
    private var quickDiagnosticsMenuBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // System Diagnostics
                quickCommandPill("⚡️ CPU/RAM", cmd: "top -l 1 | head -n 12")
                quickCommandPill("💾 Disk Usage", cmd: "df -h /")
                quickCommandPill("🍏 macOS Version", cmd: "sw_vers")
                quickCommandPill("🌿 Git Status", cmd: "git status -sb")
                quickCommandPill("🌿 Git Log", cmd: "git log --oneline -n 5")
                quickCommandPill("🍺 Brew Doctor", cmd: "brew doctor")
                quickCommandPill("🐍 Python Version", cmd: "python3 --version")
                quickCommandPill("🌐 Ports in Use", cmd: "lsof -i -P -n | head -n 10")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        }
        .background(Color.white.opacity(0.03))
    }

    @ViewBuilder
    private func quickCommandPill(_ label: String, cmd: String) -> some View {
        Button(action: {
            HapticFeedback.selection()
            runCommand(cmd)
        }) {
            Text(label)
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. Free Local Models 1-Click Hub Drawer
    private var freeModelHubDrawer: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.cyan)
                Text("Free Curated Local Models (1-Click Install — Zero Installer Hassle)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                if !tinyEngine.isOllamaRunning {
                    Button(action: {
                        tinyEngine.installAndLaunchOllamaEngine()
                    }) {
                        Text(tinyEngine.isInstallingOllamaCLI ? "Installing Engine..." : (GenieCapabilities.canInstallExternalRuntimes ? "Setup Engine via Brew" : "Get Engine (Free)"))
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.cyan))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Model Cards Grid
            HStack(spacing: 8) {
                ForEach(tinyEngine.curatedFreeModels.prefix(4)) { card in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: card.iconName)
                                .foregroundColor(.cyan)
                                .font(.system(size: 11))
                            Text(card.name)
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }

                        Text(card.description)
                            .font(.system(size: 8.5))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                            .frame(height: 24)

                        HStack {
                            Text("\(card.parameterSize) • \(card.displayDiskSize)")
                                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.9))

                            Spacer()

                            if tinyEngine.downloadingModelId == card.id {
                                ProgressView(value: tinyEngine.downloadProgress)
                                    .frame(width: 45)
                                    .scaleEffect(0.7)
                            } else {
                                Button(action: {
                                    tinyEngine.pullModel(card: card)
                                }) {
                                    Text("Install")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2.5)
                                        .background(Capsule().fill(Color.cyan.opacity(0.85)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.55)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cyan.opacity(card.isRecommended ? 0.4 : 0.15), lineWidth: 1))
                }
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.75))
    }

    // MARK: - 4. Terminal Console Screen
    private var terminalConsoleScreen: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                Text(terminalOutput)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(Color.green.opacity(0.92))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .id("terminal_bottom")
            }
            .onChange(of: terminalOutput) { _, _ in
                proxy.scrollTo("terminal_bottom", anchor: .bottom)
            }
        }
    }

    // MARK: - 5. Terminal Command Prompt Bar
    private var terminalCommandPromptBar: some View {
        HStack(spacing: 8) {
            Text("zsh ❯")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.green)

            TextField("Enter shell command or paste LeetCode test...", text: $terminalInput)
                .textFieldStyle(.plain)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundColor(.white)
                .focused($isTerminalFocused)
                .onSubmit {
                    submitTerminalInput()
                }

            if isRunningCommand {
                ProgressView().scaleEffect(0.6)
            }

            Button(action: { submitTerminalInput() }) {
                Image(systemName: "return")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.black.opacity(0.85))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.12)), alignment: .top)
    }

    // MARK: - 6. LeetCode Cookbook Sidebar
    private var leetCodeCookbookSidebar: some View {
        VStack(spacing: 0) {
            // Cookbook Header
            HStack {
                Image(systemName: "curlybraces.square.fill")
                    .foregroundColor(.yellow)
                Text("LeetCode Algorithms")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(leetCodeCookbooks.count) Recipes")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(10)
            .background(Color.black.opacity(0.5))

            // Recipes List
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    ForEach(leetCodeCookbooks) { recipe in
                        recipeCardView(recipe)
                    }
                }
                .padding(8)
            }
        }
        .background(Color.black.opacity(0.4))
    }

    @ViewBuilder
    private func recipeCardView(_ recipe: LeetCodeRecipe) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(recipe.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(recipe.difficulty)
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(recipe.difficultyColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(recipe.difficultyColor.opacity(0.15)))
            }

            Text(recipe.promptSummary)
                .font(.system(size: 9.5))
                .foregroundColor(.white.opacity(0.7))

            HStack {
                Text("Time: \(recipe.timeComplexity)")
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.yellow.opacity(0.9))
                Text("•")
                    .foregroundColor(.white.opacity(0.3))
                Text("Space: \(recipe.spaceComplexity)")
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.9))
            }

            // Action Buttons
            HStack(spacing: 6) {
                // Run in Terminal
                Button(action: {
                    HapticFeedback.heavy()
                    runCommand(recipe.testRunnerCommand)
                    showToast("Running \(recipe.title) in Terminal! 🚀")
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "play.fill")
                        Text("Run in Zsh")
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green))
                }
                .buttonStyle(.plain)

                // Copy Swift Solution
                Button(action: {
                    HapticFeedback.selection()
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(recipe.swiftSolution, forType: .string)
                    showToast("Copied Swift Code! 📋")
                }) {
                    Text("Swift")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                }
                .buttonStyle(.plain)

                // Copy Python Solution
                Button(action: {
                    HapticFeedback.selection()
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(recipe.pythonSolution, forType: .string)
                    showToast("Copied Python Code! 📋")
                }) {
                    Text("Python")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.10), lineWidth: 0.8))
    }

    private func submitTerminalInput() {
        let clean = terminalInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        terminalInput = ""
        runCommand(clean)
    }

    private func runCommand(_ cmd: String) {
        isRunningCommand = true
        terminalOutput += "\n$ \(cmd)\n"

        // No shell in the sandboxed build (Guideline 2.5.1).
        guard GenieCapabilities.canSpawnSubprocesses else {
            terminalOutput += GenieCapabilities.unavailableMessage("The terminal") + "\n"
            isRunningCommand = false
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-c", cmd]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                task.waitUntilExit()
                let output = String(data: data, encoding: .utf8) ?? "Done."
                DispatchQueue.main.async {
                    self.isRunningCommand = false
                    self.terminalOutput += output.isEmpty ? "[Process exited with code 0]\n" : "\(output)\n"
                }
            } catch {
                DispatchQueue.main.async {
                    self.isRunningCommand = false
                    self.terminalOutput += "Error executing command: \(error.localizedDescription)\n"
                }
            }
        }
    }

    private func showToast(_ msg: String) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
            toastNotification = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { self.toastNotification = nil }
        }
    }
}
