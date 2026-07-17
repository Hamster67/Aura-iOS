# Aura: Liquid Glass 🌌

<p align="center">
  <a href="#-繁體中文">繁體中文</a> • 
  <a href="#-english">English</a>
</p>

---

## 🇹🇼 繁體中文

> **「今天，慢慢完成。」**
> Aura 是一款基於 iOS 原生生態系打造的極簡微習慣追蹤器。徹底捨棄傳統的「勾選打卡」，改以「長按卡片注入液態霓虹能量」的儀式感，將日常習慣轉化為一場療癒的全息視覺饗宴。

### ✨ 核心特性
*   **極致液態玻璃美學：** 整合 iOS 17+ Metal Shaders (`distortionEffect`)。手指觸碰螢幕時，底層高度毛玻璃化（Blur radius 40+）的畫布會激發具備物理衰減的正弦波纹折射。
*   **去商務化流體互動：** 結合 `CoreMotion` 陀螺儀數據。手機傾斜時，如微型微管般的習慣圖示內部，發光漸層會滑順地隨重力流動沉澱。
*   **多 Target 本地優先架構：** 採用 `SwiftData` 作為底層資料庫，並透過 `App Groups`（`group.com.aura.liquidglass`）實現主程式與動態島之間的低延遲數據共享。
*   **動態島液態蓄力艙：** 支援 `ActivityKit` (Live Activities)。在鎖定畫面展示極薄透光的膠囊進度條；在動態島則以順時針填滿的微型液態進度環與流體展開艙實時互動。
*   **毀滅式捏碎動效：** 執行刪除時，需透過雙指捏合手勢（Pinch-in），卡片將劇烈抖動並爆裂成數百個半透明折射水珠散落消失。

### 🛠️ 技術棧
*   **UI 框架：** SwiftUI (iOS 17.0+)
*   **圖形渲染：** Metal Shading Language (MSL)
*   **資料持久化：** SwiftData
*   **硬體感測：** CoreMotion (陀螺儀低通濾波)
*   **即時擴充：** ActivityKit (Live Activities & Dynamic Island)

### 🚀 CI/CD 自動化導出
本專案已完全解耦 Code Signing 簽章設定。推送到 GitHub 後，會透過 `.github/workflows/ios-build.yml` 的 macOS 虛擬機自動執行 `xcodebuild clean archive`，並將編譯成功的 `.ipa` 導出為專案 Artifact。

---

## 🇺🇸 English

> **"Slowly, mindfully, complete your day."**
> Aura is a minimalistic, native iOS micro-habit tracker. It completely replaces traditional "checkbox checking" with an immersive ritual of "holding to infuse liquid neon energy," turning daily routines into a therapeutic holographic visual experience.

### ✨ Key Features
*   **Liquid Glass Aesthetics:** Leverages iOS 17+ Metal Shaders (`distortionEffect`). Tapping any area triggers a damped sinusoidal fluid ripple, causing dynamic lens distortion over a deeply blurred (radius 40+) background canvas.
*   **Anti-Corporate Fluid Interactions:** Powered by `CoreMotion` gyroscope data. Tilting the device causes the glowing linear gradients inside the continuously rounded icons to flow and settle smoothly according to physical gravity.
*   **Local-First, Multi-Target Architecture:** Utilizes `SwiftData` for local persistence, bridged via `App Groups` (`group.com.aura.liquidglass`) to unlock ultra-low latency data state synchronization between the Main App and Widget targets.
*   **Dynamic Island Fluid Capsule:** Supported by `ActivityKit` (Live Activities). Features an ultra-thin glassmorphic lock screen widget and a dynamic island interface that displays a clockwise-filling liquid progress ring.
*   **Shatter Physics Deletion:** To prevent accidental deletion, habits must be destroyed via a pinch-in gesture. The card shakes violently before exploding into hundreds of semi-transparent refractive droplets that scatter under gravity.

### 🛠️ Tech Stack
*   **UI Framework:** SwiftUI (iOS 17.0+)
*   **Graphics & Shading:** Metal Shading Language (MSL)
*   **Data Persistence:** SwiftData
*   **Hardware Sensors:** CoreMotion (Low-pass filtered gyroscope data)
*   **Live Extensions:** ActivityKit (Live Activities & Dynamic Island)

### 🚀 CI/CD Automated Export
The project's code signing properties are decoupled from the build configuration. Upon pushing to GitHub, `.github/workflows/ios-build.yml` triggers a macOS runner to execute `xcodebuild clean archive` with `CODE_SIGNING_ALLOWED=NO`, successfully exporting the compiled `.ipa` as a workflow artifact.