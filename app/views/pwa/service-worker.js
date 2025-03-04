// Process Web Push notifications
self.addEventListener("push", async (event) => {
  console.log('[Service Worker] Push received');
  
  if (event.data) {
    try {
      const { title, body, icon, badge, data } = await event.data.json();
      const options = {
        body,
        icon: icon || '/icon.png',
        badge: badge || '/icon.png',
        data: data || {}
      };
      
      event.waitUntil(self.registration.showNotification(title, options));
    } catch (error) {
      console.error('[Service Worker] Error showing notification:', error);
    }
  }
});

// Handle notification click events
self.addEventListener("notificationclick", function(event) {
  console.log('[Service Worker] Notification click received');
  
  event.notification.close();
  
  const path = event.notification.data.path || '/';
  
  event.waitUntil(
    clients.matchAll({ type: "window" }).then((clientList) => {
      for (let i = 0; i < clientList.length; i++) {
        let client = clientList[i];
        let clientPath = (new URL(client.url)).pathname;

        if (clientPath == path && "focus" in client) {
          return client.focus();
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(path);
      }
    })
  );
});
