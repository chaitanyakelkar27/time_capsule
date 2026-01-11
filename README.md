# TimeCapsule 🔐

A digital vault where users can send messages, photos, or videos that stay "locked" until a specific future date or location is reached.

## Features

- **Time-Based Unlocking**: Capsules unlock at a specific future date/time
- **Location-Based Unlocking**: Capsules unlock when recipient reaches a specific location
- **Reaction Videos**: Recipients can record and send reaction videos
- **End-to-End Encryption**: All capsule content is encrypted for privacy
- **Push Notifications**: Firebase Cloud Messaging for unlock notifications

## Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile/web framework
- **Provider** - State management
- **Firebase SDK** - Authentication, Firestore, Storage, Cloud Functions

### Backend
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL database
- **Firebase Storage** - Media storage
- **Cloud Functions** - Serverless backend (TypeScript/Node.js)
- **Firebase Cloud Messaging** - Push notifications

## Project Structure

```
time_capsule/
├── frontend/          # Flutter application
│   ├── lib/
│   │   ├── models/           # Data models
│   │   ├── services/         # Business logic services
│   │   ├── providers/        # State management
│   │   ├── screens/          # UI screens
│   │   ├── widgets/          # Reusable widgets
│   │   └── utils/            # Helper functions
│   └── pubspec.yaml
└── backend/           # Firebase backend
    ├── functions/            # Cloud Functions (TypeScript)
    ├── firestore.rules      # Firestore security rules
    ├── storage.rules        # Storage security rules
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
   flutterfire configure
   ```

3. **Backend Setup**
   ```bash
   cd backend/functions
   npm install
   cd ..
   firebase login
   firebase use --add
   ```

4. **Run the app**
   ```bash
   cd frontend
   flutter run -d chrome  # For web
   flutter run            # For mobile (connected device)
   ```

## Features in Development

- [x] User Authentication (Email/Password)
- [x] User Profile Management
- [ ] Create Time-Locked Capsules
- [ ] Create Location-Locked Capsules
- [ ] Cloud Function for Time-Based Unlocking
- [ ] Cloud Function for Location-Based Unlocking
- [ ] Push Notifications
- [ ] Reaction Video Recording
- [ ] Media Encryption/Decryption

## Contributing

This is a personal project for learning purposes.

## License

MIT License

## Author

Chaitanya Kelkar
