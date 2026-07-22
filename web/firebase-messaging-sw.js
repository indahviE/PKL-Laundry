// Firebase Cloud Messaging Service Worker
// Wajib ada di folder web/ (root, sejajar sama index.html) supaya
// FCM bisa nerima push notification di platform web.

importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

// Config ini diambil persis dari FirebaseOptions.web di
// lib/firebase_options.dart -- kalau nanti config web berubah
// (misal ganti project Firebase), update juga di sini.
firebase.initializeApp({
  apiKey: "AIzaSyBgHDOAEiDkxQkbApNkTNowiGG_zyIVIVM",
  authDomain: "netwash-id.firebaseapp.com",
  projectId: "netwash-id",
  storageBucket: "netwash-id.firebasestorage.app",
  messagingSenderId: "397480771765",
  appId: "1:397480771765:web:fb84f2f41d77cfc94d3efc",
});

const messaging = firebase.messaging();

// Handle notifikasi yang masuk saat tab/browser sedang di background.
messaging.onBackgroundMessage((payload) => {
  console.log("Menerima pesan background:", payload);
  const notificationTitle = payload.notification?.title ?? "Netwash";
  const notificationOptions = {
    body: payload.notification?.body ?? "",
    icon: "/icons/Icon-192.png",
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});