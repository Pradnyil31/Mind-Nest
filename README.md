# MindNest 🧠🪺

MindNest is a comprehensive personal wellness and routine tracking application designed to help users cultivate healthy habits, improve sleep, and maintain mental well-being. Built with Flutter and powered by Google Gemini AI, MindNest offers meaningful insights and a supportive companion for your daily journey.

## ✨ Features

-   🤖 AI Companion: Chat with a supportive AI assistant powered by Google's Gemini API for encouragement, advice, and conversation.
-   📅 Routine Tracking: Create and manage daily routines with customizable schedules.
-   😴 Sleep Improvement: Track sleep patterns and get personalized motive-based recommendations for better rest.
-   📊 Progress & Analytics: Visualize your consistency and progress over time with interactive charts.
-   🧘 Mindfulness: Access breathing exercises and other mindfulness tools directly within the app.
-   🔐 Secure Authentication: Seamless sign-in with Google and Email/Password using Firebase Auth.
-   ☁️ Cloud Sync: Your data is synced across devices using Cloud Firestore.

## 🛠️ Tech Stack

-   Frontend: Flutter (Dart)
-   Backend / Database: Firebase (Firestore, Auth)
-   State Management: Riverpod
-   AI Integration: Google Generative AI (Gemini)
-   Charts: FL Chart

## 🚀 Getting Started

### Prerequisites

-   Flutter SDK installed ([Installation Guide](https://flutter.dev/docs/get-started/install))
-   A Firebase project set up ([Firebase Guide](https://firebase.google.com/docs/flutter/setup))
-   A Google Gemini API Key ([Get API Key](https://ai.google.dev/))

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/yourusername/mindnest.git
    cd mindnest
    ```

2.  Install dependencies:
    ```bash
    flutter pub get
    ```

3.  Configure Firebase:
    -   Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the respective `android/app` and `ios/Runner` directories.

4.  **Set up API Keys (CRITICAL)**:
    -   You must provide your Google Gemini API key when running or building the app.
    -   **Option A: VS Code (Recommended)**
        -   Open the project in VS Code.
        -   Go to the "Run and Debug" tab.
        -   Select "MindNest (Dev)" and click the Play button.
        -   *(Note: The `launch.json` is pre-configured with a placeholder key. Update it in `.vscode/launch.json` if needed)*

    -   **Option B: Terminal**
        -   Run with the key passed as a dart-define:
        ```bash
        flutter run --dart-define=GEMINI_API_KEY=YOUR_ACTUAL_API_KEY
        ```

5.  Run the app:
    ```bash
    flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY
    ```

## 📸 Screenshots

| Home Screen | Routine Tracker | AI Chat |
|:-----------:|:---------------:|:-------:|
| ![Home](assets/images/home_placeholder.png) | ![Routine](assets/images/routine_placeholder.png) | ![Chat](assets/images/chat_placeholder.png) |

(Note: Replace placeholder paths with actual screenshot paths)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
