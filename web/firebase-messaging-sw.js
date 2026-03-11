importScripts("https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBy4sE8Xy26wvZZfiSRwPmwgpNAGWWOzNM",
  appId: "1:1063618731673:web:e9871b789bba454efba208",
  messagingSenderId: "1063618731673",
  projectId: "helpdesk-unila",
  authDomain: "helpdesk-unila.firebaseapp.com",
  storageBucket: "helpdesk-unila.firebasestorage.app",
  measurementId: "G-KKWL63MHFC",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("helpdesk background message", payload);
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  const data = event.notification?.data || {};
  const fcmMessage = data.FCM_MSG || {};
  const ticketId =
    data.ticketId ||
    data.ticket_id ||
    fcmMessage?.data?.ticket_id ||
    "";
  const targetUrl = ticketId
    ? `/#/notifications?ticketId=${encodeURIComponent(ticketId)}`
    : "/#/notifications";

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ("navigate" in client) {
          return client.navigate(targetUrl).then(() => client.focus());
        }
        if ("focus" in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
      return undefined;
    }),
  );
});
