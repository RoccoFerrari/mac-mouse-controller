# Mac Mouse Controller

**Mac Mouse Controller** is a native macOS utility written in Swift that allows you to fully customize your mouse behavior. It leverages Core Graphics Event Taps (`CGEventTap`) to intercept and modify system-wide mouse input, enabling features like smooth scrolling, custom button mapping, and navigation gestures on standard mice.

## 🚀 Key Features

* **Custom Button Mapping:** Remap any physical mouse button (Left, Right, Middle, Side Buttons) to custom actions.
* **Modifier Support:** Create complex rules by combining mouse clicks with keyboard modifiers (e.g., `Cmd + Click`, `Ctrl + Wheel`).
* **Smooth Scrolling:** Implements a physics-based rendering loop (60fps) to provide fluid, trackpad-like scrolling on standard wheel mice.
* **Scroll Direction Control:** Independently invert scroll direction ("Natural Scrolling") without affecting the system trackpad settings.
* **System Integrations:** Trigger macOS features like Mission Control, App Exposé, Launchpad, and Show Desktop.
* **Navigation Actions:** map buttons to switch Spaces (Virtual Desktops), navigate Browser History (Back/Forward), or Smart Zoom.
* **Adjust Sensitivity:** modify the scroll speed multiplier dynamically.

## 🛠️ Tech Stack

* **Language:** Swift 5
* **UI Framework:** SwiftUI
* **State Management:** Combine (`ObservableObject`, `@Published`)
* **Core Logic:** Core Graphics (`CGEvent`, `CGEventTap`), Carbon (Keycodes)
* **System Services:** ServiceManagement (Launch at Login), Accessibility API

## ⚙️ Installation & Setup

### 📥 Download (Pre-compiled)
Don't want to build from source? You can download the latest version directly from the Releases page.

1. **[Download mac-mouse-controller.zip](https://github.com/RoccoFerrari/mac-mouse-controller/releases/latest)**
2. Unzip the file and move `mac-mouse-controller.app` to your **Applications** folder.

> **⚠️ Important:** Since this app is not signed with a paid Apple Developer ID, macOS might tell you the app is "damaged" or "cannot be opened" on the first launch. To fix this:
>
> 1. Open **Terminal**.
> 2. Run the following command:
>    ```bash
>    xattr -cr /Applications/mac-mouse-controller.app
>    ```
> 3. Launch the app again.

### Prerequisites (For building)
* macOS 13.0+ (Ventura or newer recommended)
* Xcode 14+ (for building from source)

### Building from Source
1.  Clone the repository:
    ```bash
    git clone [https://github.com/RoccoFerrari/mac-mouse-controller.git](https://github.com/RoccoFerrari/mac-mouse-controller.git)
    ```
2.  Open `mac-mouse-controller.xcodeproj` in Xcode.
3.  **Important:** Ensure **App Sandbox** is DISABLED in the "Signing & Capabilities" tab. This app requires low-level access to input devices which is not allowed in the Sandbox.
4.  Build and Run (`Cmd + R`).

### Permissions
Because this application intercepts global input events, it requires **Accessibility Permissions**.

1.  On first launch, the app will show a "Permissions Needed" screen.
2.  Click **"Open Settings"**.
3.  Navigate to **System Settings** -> **Privacy & Security** -> **Accessibility**.
4.  Enable the toggle next to **Mac Mouse Controller**.
5.  If the app does not detect the change immediately, restart the app.

## 📖 Architecture Overview

The project follows a clean architecture separating the UI from the low-level event handling.

### 1. AppState (ViewModel)
The `AppState` class acts as the single source of truth. It manages:
* **Permissions Monitoring:** A background task checks `AXIsProcessTrusted` status in real-time.
* **User Profile:** Persists rules and settings to `UserDefaults` using `Codable`.
* **Engine Control:** Starts/Stops the `MouseHookService` based on app state.

### 2. MouseHookService (Core)
This service wraps the C-based `CGEvent.tapCreate` API. It creates a `CFMachPort` and attaches it to the `RunLoop`. It uses a **Chain of Responsibility** pattern to process events:
* Incoming events are passed through a list of `MouseEventHandler` objects.
* Handlers can modify the event, pass it through, or return `nil` to consume (block) the event.

### 3. ConfigurableHandler
The main logic engine. It:
* Matches incoming events against the user's `MappingProfile`.
* Runs the **Smooth Scrolling** physics engine (calculates velocity and friction, generates synthetic scroll events).
* Executes actions defined in `ActionDefinitions.swift`.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1.  Fork the project.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note:** This application uses private system APIs (`CGEventTap`). It is intended for personal use or distribution outside the Mac App Store.
