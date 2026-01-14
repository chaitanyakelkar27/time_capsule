importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker
firebase.initializeApp({
    apiKey: "AIzaSyAYkiYuoXN3dBT-ZL8jLFslC9YSahH0xR0",
    authDomain: "time-capsule-c4c2a.firebaseapp.com",
    projectId: "time-capsule-c4c2a",
    storageBucket: "time-capsule-c4c2a.firebasestorage.app",
    messagingSenderId: "177675830046",
    appId: "1:177675830046:web:c5da739d396b1ca2ae3f0f"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
    console.log('Received background message:', payload);

    const notificationTitle = payload.notification?.title || 'TimeCapsule';
    const notificationOptions = {
        body: payload.notification?.body || 'You have a new notification',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});
