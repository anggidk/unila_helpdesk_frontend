importScripts("https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js");
importScripts("/firebase-web-config.js");

if (!self.FIREBASE_WEB_CONFIG) {
  throw new Error("firebase-web-config.js belum tersedia.");
}

firebase.initializeApp(self.FIREBASE_WEB_CONFIG);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("helpdesk background message", payload);
  const data = payload?.data || {};
  const title = data.title || payload?.notification?.title || "Helpdesk";
  const body = data.body || payload?.notification?.body || "Ada pembaruan notifikasi.";
  const ticketId = data.ticketId || data.ticket_id || "";
  const link =
    data.link ||
    payload?.fcmOptions?.link ||
    "";

  self.registration.showNotification(title, {
    body,
    icon: "/assets/assets/logo/Logo_unila.png",
    badge: "/assets/assets/logo/Logo_unila.png",
    tag: ticketId ? `ticket-${ticketId}` : "helpdesk-notification",
    data: {
      ticketId,
      ticket_id: ticketId,
      link,
    },
  });
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  const data = event.notification?.data || {};
  const fcmMessage = data.FCM_MSG || {};
  const link =
    data.link ||
    fcmMessage?.fcmOptions?.link ||
    "";
  const ticketId =
    data.ticketId ||
    data.ticket_id ||
    fcmMessage?.data?.ticket_id ||
    "";
  const targetPath = ticketId
    ? `/#/notifications?ticketId=${encodeURIComponent(ticketId)}`
    : "/#/notifications";
  const targetUrl = link || new URL(targetPath, self.location.origin).href;

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (!client.url.startsWith(self.location.origin)) {
          continue;
        }
        if ("navigate" in client) {
          return client
            .navigate(targetUrl)
            .then(() => ("focus" in client ? client.focus() : undefined))
            .catch(() => (clients.openWindow ? clients.openWindow(targetUrl) : undefined));
        }
        if ("focus" in client) {
          return client
            .focus()
            .then(() => client)
            .catch(() => (clients.openWindow ? clients.openWindow(targetUrl) : undefined));
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
      return undefined;
    }),
  );
});
