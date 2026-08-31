"use strict";

// Increment this exact cache name for every release. A stale Harbor cache must
// never silently survive a clinical-content correction or privacy fix.
const CACHE_NAME = "harbor-shell-0.1.0-alpha.21";
const RELEASE_CORE = [
  "./",
  "./index.html",
  "./flutter_bootstrap.js",
  "./flutter_bootstrap.js?v=0.1.0-alpha.21",
  "./flutter.js",
  "./harbor_service_worker.js",
  "./main.dart.js",
  "./main.dart.mjs",
  "./main.dart.wasm",
  "./manifest.json",
  "./version.json",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      await Promise.all(
        RELEASE_CORE.map(async (asset) => {
          // A prior Harbor worker and the browser HTTP cache can both hold an
          // older unversioned main.dart.* file. Force the network revalidation
          // that makes CACHE_NAME an honest snapshot of this release.
          const request = new Request(asset, { cache: "reload" });
          const response = await fetch(request);
          if (!response.ok) {
            throw new Error(`Harbor could not cache ${asset}.`);
          }
          await cache.put(asset, response);
        }),
      );
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    // Keep the prior Harbor cache as an offline fallback until this release has
    // loaded and cached its renderer, fonts, icons, and shaders. A later
    // maintenance policy may prune superseded caches only after rollback tests.
    self.clients.claim(),
  );
});

self.addEventListener("fetch", (event) => {
  const requestUrl = new URL(event.request.url);
  if (event.request.method !== "GET" || requestUrl.origin !== self.location.origin) return;

  if (event.request.mode === "navigate") {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put("./index.html", copy));
          return response;
        })
        .catch(async () => {
          const current = await (
            await caches.open(CACHE_NAME)
          ).match("./index.html");
          return current || caches.match("./index.html");
        }),
    );
    return;
  }

  event.respondWith(
    caches.open(CACHE_NAME).then(async (cache) => {
      const current = await cache.match(event.request);
      if (current) return current;
      try {
        const response = await fetch(event.request);
        if (response.ok) await cache.put(event.request, response.clone());
        return response;
      } catch (error) {
        const previous = await caches.match(event.request);
        if (previous) return previous;
        throw error;
      }
    }),
  );
});
