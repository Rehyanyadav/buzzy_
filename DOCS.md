# Nexus - Couple's Messaging App

Nexus is a premium, secure, and intimate messaging application designed specifically for couples. It features real-time chat, a shared scrapbook, and a secure vault for private moments.

## Features

### 💬 Advanced Chat
- **Real-time Messaging**: Instant message delivery using Supabase Realtime.
- **Media Support**: Send and view images, videos, and documents.
- **Audio Messages**: Record and play voice notes with an integrated player.
- **Reply & Forward**: Standard messaging features for better communication.
- **WhatsApp-like UI**: Chronological grouping, date dividers, and read receipts.
- **Security**: Block/Unblock functionality and clear conversation options.

### 🔒 Privacy & Security
- **Local Auth**: Biometric/Passcode protection to unlock the app.
- **Identity**: Secure authentication via Supabase Auth.
- **Reset Password**: Easy recovery via email.
- **The Vault**: A dedicated secure space for sensitive content.

### 💖 Shared Space
- **Scrapbook**: A shared gallery for your most precious photos and memories.
- **Mood Sync**: Share how you're feeling with your partner in real-time.
- **Online Presence**: Real-time partner online status and typing indicators.

## Tech Stack
- **Framework**: Flutter (Dart)
- **Backend**: Supabase (Auth, Database, Realtime, Storage)
- **State Management**: Flutter Riverpod
- **Local Auth**: `local_auth` package
- **Media**: `record`, `audioplayers`, `file_picker`, `image_picker`

## Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Dart SDK
- A Supabase Project

### Environment Setup
Update the Supabase configuration in `lib/main.dart`:
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### Installation
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Run `flutter run` on your preferred device.

## Database Schema
The app uses the following tables in Supabase:
- `profiles`: User information, partner linking, moods, and blocked users.
- `messages`: Chat message history.
- `scrapbook`: Shared media items.
- `vault`: Secure items (encrypted/protected).

---
Created with ❤️ for Nexus users.
