# TimeCapsule

A Flutter-based digital vault where users can send messages, photos, or videos that stay "locked" until a specific future date or location is reached.

## Features

- ✅ **User Authentication** - Email/password authentication with Firebase
- ✅ **Time-Based Unlocking** - Capsules unlock at a specific future date/time
- ✅ **Location-Based Unlocking** - Capsules unlock when recipient reaches a specific location
- ✅ **Reaction Videos** - Recipients can record and send reaction videos
- ✅ **Real-time Updates** - Live sync of capsules using Firestore streams
- ✅ **Push Notifications** - Firebase Cloud Messaging for unlock notifications
- ✅ **Modern UI** - Gradient backgrounds, rounded cards, professional design
- ✅ **Image Assets** - Professional images from Unsplash (no emojis)
- ✅ **Profile Statistics** - Track sent, received, locked, and unlocked capsules

## Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile/web framework
- **Provider** - State management
- **Firebase SDK** - Authentication, Firestore, Storage, Cloud Functions
- **Material Design 3** - Modern UI components
- **Cached Network Image** - Efficient image loading
- **Video Player** - Video playback support

### Backend
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL database with real-time sync
- **Firebase Storage** - Media storage (images, videos)
- **Cloud Functions** - Serverless backend (TypeScript/Node.js)
- **Firebase Cloud Messaging** - Push notifications

## Project Structure

```
time_capsule/
├── frontend/                    # Flutter application
│   ├── lib/
│   │   ├── models/             # Data models (CapsuleModel, UserModel)
│   │   ├── services/           # Business logic (Auth, Firestore, Storage, Location)
│   │   ├── providers/          # State management (AuthProvider, CapsuleProvider)
│   │   ├── screens/            # UI screens
│   │   │   ├── auth/           # Login, signup screens
│   │   │   ├── home/           # Home screen with sent/received tabs
│   │   │   ├── capsule/        # Create, detail screens
│   │   │   └── profile/        # Profile, settings screens
│   │   ├── widgets/            # Reusable widgets (CapsuleCard)
│   │   └── utils/              # Helper functions
│   ├── assets/
│   │   └── images/             # Professional images from Unsplash
│   ├── web/
│   │   └── firebase-messaging-sw.js  # Service worker for notifications
│   └── pubspec.yaml
└── backend/                     # Firebase backend
    ├── functions/              # Cloud Functions (TypeScript)
    ├── firestore.rules         # Firestore security rules
    ├── storage.rules           # Storage security rules
    └── firebase.json

```

## Getting Started

### Prerequisites
- Flutter SDK (>=3.10.4)
- Node.js (v20+)
- Firebase CLI
- Firebase project with Authentication, Firestore, Storage, and Functions enabled

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/chaitanyakelkar27/time_capsule.git
   cd time_capsule
   ```

2. **Frontend Setup**
   ```bash
   cd frontend
   flutter pub get
   ```

3. **Firebase Configuration**
   - Your Firebase config is already in `lib/firebase_options.dart`
   - Web service worker is configured in `web/firebase-messaging-sw.js`

4. **Run the app**
   ```bash
   cd frontend
   flutter run -d chrome  # For web
   flutter run            # For mobile (connected device/emulator)
   ```

## How to Use

### Creating a Capsule
1. Tap the **"Create Capsule"** button
2. Add a title and message
3. Optionally add an image or video
4. Select a recipient from the dropdown
5. Choose unlock type:
   - **Time-Based**: Select a future date and time
   - **Location-Based**: Capture a GPS location
6. Tap **"Create Capsule"**

### Viewing Capsules
- **Sent Tab**: See all capsules you've sent to others
- **Received Tab**: See all capsules sent to you
- **Locked Capsules**: Show countdown timer or location requirement
- **Unlocked Capsules**: View full content and record reactions

### Profile
- View your statistics (sent, received, locked, unlocked)
- Edit profile information
- Manage settings and notifications

## UI Improvements

✅ Fixed layout overflow errors  
✅ Replaced all emojis with professional Unsplash images  
✅ Added gradient backgrounds and rounded corners  
✅ Improved visual hierarchy and spacing  
✅ Added image-based lock icons  
✅ Enhanced statistics cards with gradients  
✅ Better empty states with images  

## Troubleshooting

**No recipients available**: Create multiple user accounts to test sending capsules between users.

**Sent capsules not showing**: Check browser console for logs. The app uses real-time Firestore listeners.

**Service worker error**: Firebase credentials are already configured in `web/firebase-messaging-sw.js`.

## Contributing

This is a personal project created for learning purposes. Feel free to fork and experiment!

## License

MIT License

## License

MIT License

## Author

Chaitanya Kelkar
