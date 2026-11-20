// Always load the newest page from the network (no stale copies), so updates show up right away.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', e => {
  if (e.request.mode === 'navigate') e.respondWith(fetch(e.request, {cache: 'no-store'}).catch(() => fetch(e.request)));
});
