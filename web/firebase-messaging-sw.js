// Firebase messaging service worker for Mindload app
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Firebase configuration
firebase.initializeApp({
  apiKey: 'AIzaSyD5W9fk1gE987PBexYcone_QVapotA_kHM',
  authDomain: 'lca5kr3efmasxydmsi1rvyjoizifj4.firebaseapp.com',
  projectId: 'lca5kr3efmasxydmsi1rvyjoizifj4',
  storageBucket: 'lca5kr3efmasxydmsi1rvyjoizifj4.firebasestorage.app',
  messagingSenderId: '884947669542',
  appId: '1:884947669542:web:db39decdf401cc5ba74ce7',
  measurementId: 'G-S8FXSS0QKM'
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'Mindload Notification';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');
  
  event.notification.close();
  
  // Open the app when notification is clicked
  event.waitUntil(
    clients.openWindow('/')
  );
});
