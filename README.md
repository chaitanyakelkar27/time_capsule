# TimeCapsule ⏰📍

A Flutter-based digital vault where users can send messages, photos, or videos that stay "locked" until a specific future date or location is reached. Enhanced with AI-powered message generation using Groq.

## 🚀 Live Demo

**Deployed App**: [https://time-capsule-c4c2a.web.app](https://time-capsule-c4c2a.web.app)

Access the app instantly on any device - no installation required!

## ✨ Features

- ✅ **User Authentication** - Email/password authentication with Firebase
- ✅ **Time-Based Unlocking** - Capsules unlock at a specific future date/time
- ✅ **Location-Based Unlocking** - Capsules unlock when recipient reaches a specific location
- ✅ **AI Message Generation** - Generate creative, heartfelt messages with Groq AI
- ✅ **AI Message Enhancement** - Polish and improve existing messages with AI
- ✅ **Reaction Videos** - Recipients can record and send reaction videos
- ✅ **Real-time Updates** - Live sync of capsules using Firestore streams
- ✅ **Push Notifications** - Firebase Cloud Messaging for unlock notifications
- ✅ **Midnight Glass UI** - Premium design with glassmorphism effects and electric violet accents
- ✅ **Image Assets** - Professional images from Unsplash
- ✅ **Profile Statistics** - Track sent, received, locked, and unlocked capsules
- ✅ **Progressive Web App** - Install on mobile devices for app-like experience

## 🛠 Tech Stack

### Frontend
- **Flutter 3.38.5** - Cross-platform mobile/web framework
- **Provider** - State management
- **Firebase SDK** - Authentication, Firestore, Storage, Cloud Functions
- **Groq API** - LLM-based message generation and enhancement
- **Material Design 3** - Modern UI components
- **Cached Network Image** - Efficient image loading
- **Video Player** - Video playback support
- **Geolocator** - Location services
- **Permission Handler** - Runtime permissions

### Backend
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL database with real-time sync
- **Firebase Storage** - Media storage (images, videos)
- **Cloud Functions** - Serverless backend (TypeScript/Node.js)
- **Firebase Cloud Messaging** - Push notifications
- **Firebase Hosting** - Static web hosting

### AI Integration
- **Groq Chat Completions** - AI-powered message suggestions and enhancements
- **Context-Aware Generation** - Personalized messages based on recipient, unlock type, and capsule title
- **Message Enhancement** - Improves writing style while maintaining sentiment

## Project Structure

```
time_capsule/
├── frontend/                    # Flutter application
│   ├── lib/
│   │   ├── models/             # Data models (CapsuleModel, UserModel)
│   │   ├── services/           # Business logic
│   │   │   ├── auth_service.dart
│   │   │   ├── firestore_service.dart
│   │   │   ├── storage_service.dart
│   │   │   ├── location_service.dart
│   │   │   ├── notification_service.dart
│   │   │   └── ai_service.dart        # Groq AI integration
│   │   ├── providers/          # State management (AuthProvider, CapsuleProvider)
│   │   ├── screens/            # UI screens
│   │   │   ├── auth/           # Login, register screens
│   │   │   ├── home/           # Home screen with sent/received tabs
│   │   │   ├── capsule/        # Create, detail screens
│   │   │   └── profile/        # Profile, settings screens
│   │   ├── widgets/            # Reusable widgets (CapsuleCard)
│   │   └── main.dart
│   ├── assets/
│   │   └── images/             # Professional images from Unsplash
│   ├── web/
│   │   ├── index.html
│   │   └── firebase-messaging-sw.js  # Service worker for notifications
│   └── pubspec.yaml
└── backend/                     # Firebase backend
    ├── functions/              # Cloud Functions (TypeScript)
    ├── public/                 # Built web app (deployed to Firebase Hosting)
    ├── firestore.rules         # Firestore security rules
    ├── storage.rules           # Storage security rules
    └── firebase.json

```

## 🎨 Design System

### Midnight Glass Theme
- **Background Gradient**: Dark navy (`#1A1F2E` → `#0F1419` → `#1E2530`)
- **Glassmorphism**: Frosted glass effects with backdrop blur
- **Accent Colors**: Electric violet gradient (`#8B5CF6` → `#C084FC`)
- **Typography**: System fonts with elegant hierarchy
- **Shadows**: Layered shadows for depth
- **Animations**: Smooth transitions and micro-interactions

## 🚀 Getting Started

### Quick Start (Use Live Demo)

Simply visit **[https://time-capsule-c4c2a.web.app](https://time-capsule-c4c2a.web.app)** in any browser!

No installation required - works on mobile, tablet, and desktop.

### Local Development Setup

#### Prerequisites
- Flutter SDK (>=3.10.4)
- Node.js (v20+)
- Firebase CLI
- Firebase project with Authentication, Firestore, Storage, Functions, and Hosting enabled
- Groq API key (for AI suggestions)

#### Installation

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

3. **Firebase and AI Configuration**
   - Firebase config is in `lib/firebase_options.dart`
   - Pass Groq secrets at runtime using dart-define:
     - `--dart-define=GROQ_API_KEY=your_key`
     - Optional: `--dart-define=GROQ_MODEL=llama-3.1-8b-instant`
   - Web service worker configured in `web/firebase-messaging-sw.js`

4. **Run the app**
   ```bash
   cd frontend
   flutter run -d chrome --dart-define=GROQ_API_KEY=your_key  # For web
   flutter run --dart-define=GROQ_API_KEY=your_key            # For mobile
   ```

5. **Deploy to Firebase Hosting**
   ```bash
   cd frontend
   flutter build web --release
   cd ../backend
   # Copy build to public folder
   firebase deploy --only hosting
   ```

## 📱 How to Use

### Creating a Capsule
1. Tap the **"Create Capsule"** button (floating action button)
2. Add a title for your capsule
3. Write a message or use **AI features**:
   - **AI Suggest**: Generate a complete heartfelt message from scratch
   - **AI Enhance**: Improve your existing message with better writing
4. Optionally add an image or video
5. Select a recipient from the dropdown
6. Choose unlock type:
   - **Time-Based**: Select a future date and time
   - **Location-Based**: Capture current GPS location and set unlock radius
7. Tap **"Create Capsule"**

### Using AI Features
- **AI Suggest**: Click to generate a creative, personalized message
  - Based on capsule title, recipient name, and unlock conditions
  - 100-150 words of heartfelt content
   - Generated in seconds using Groq
- **AI Enhance**: Click to polish your existing message
  - Improves writing style and flow
  - Maintains your original sentiment
  - Makes messages more memorable

### Viewing Capsules
- **Sent Tab**: See all capsules you've sent to others
- **Received Tab**: See all capsules sent to you
- **Locked Capsules**: Show countdown timer or location requirement with distance
- **Unlocked Capsules**: View full content, media, and record reaction videos

### Profile & Statistics
- View your capsule statistics (sent, received, locked, unlocked)
- Edit profile information and avatar
- Manage settings and notifications
- Sign out

## 🎨 Design Highlights

### Midnight Glass UI
✅ Premium glassmorphism effects with backdrop blur  
✅ Electric violet gradient accents (#8B5CF6 → #C084FC)  
✅ Dark navy background gradients  
✅ Smooth animations and transitions  
✅ Professional Unsplash imagery (no emojis)  
✅ Responsive design for all screen sizes  
✅ Consistent visual hierarchy  

### Technical Achievements
✅ Zero compilation errors (fixed 416+ errors from dependency conflicts)  
✅ Zero runtime exceptions (resolved infinite layout loops)  
✅ Optimized build artifacts (excluded from git)  
✅ Tree-shaken fonts (99% size reduction)  
✅ Progressive Web App support  
✅ Clean code architecture with services and providers  

## 🤖 Google Technologies Used

1. **Firebase Authentication** - User management
2. **Cloud Firestore** - Real-time database
3. **Firebase Storage** - Media storage
4. **Firebase Cloud Functions** - Serverless backend
5. **Firebase Cloud Messaging** - Push notifications
6. **Firebase Hosting** - Web app deployment
7. **Groq API** - AI message generation and enhancement

## 🔒 Security Features

- Firebase security rules for Firestore and Storage
- User-specific data access controls
- Secure authentication flow
- Protected media uploads
- Environment-based configuration

## 📊 Performance

- Tree-shaken assets (99% icon size reduction)
- Optimized web build (~37 seconds)
- Fast deployment (~20 seconds)
- Cached network images
- Efficient real-time listeners

## 🐛 Troubleshooting

## 🐛 Troubleshooting

**No recipients available**: Create multiple user accounts to test sending capsules between users.

**AI features not working**: Ensure `GROQ_API_KEY` is passed with `--dart-define` when running the app.

**Capsules not showing**: Check browser console for errors. The app uses real-time Firestore listeners.

**Location services**: Grant location permissions when prompted for location-based capsules.

**Push notifications**: Allow notification permissions in browser settings.

**Service worker errors**: Clear browser cache and reload. Firebase credentials are configured in `web/firebase-messaging-sw.js`.

## 🚢 Deployment

The app is deployed on Firebase Hosting and accessible at:
**[https://time-capsule-c4c2a.web.app](https://time-capsule-c4c2a.web.app)**

### Deployment Process
1. Build Flutter web app: `flutter build web --release`
2. Copy build to backend public folder
3. Deploy: `firebase deploy --only hosting`
4. Live in ~20 seconds!

## 📄 Project Documentation

For detailed information, see:
- `PROJECT_GUIDE.md` - Comprehensive project documentation
- `USER_GUIDE.md` - End-user instructions
- `DEPLOYMENT_READY.md` - Deployment checklist

## 🤝 Contributing

This project was created as a learning exercise. Feel free to:
- Fork the repository
- Submit issues
- Suggest improvements
- Create pull requests

## 📝 License

MIT License - See LICENSE file for details

## 👤 Author

**Chaitanya Kelkar**
- GitHub: [@chaitanyakelkar27](https://github.com/chaitanyakelkar27)
- Project: [Time Capsule](https://time-capsule-c4c2a.web.app)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Groq API for message generation
- Unsplash for professional imagery
- Material Design for UI guidelines

---

**Live Demo**: [https://time-capsule-c4c2a.web.app](https://time-capsule-c4c2a.web.app)  
**Repository**: [https://github.com/chaitanyakelkar27/time_capsule](https://github.com/chaitanyakelkar27/time_capsule)
