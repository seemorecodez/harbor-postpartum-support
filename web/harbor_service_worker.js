"use strict";

// Increment this exact cache name for every release. A stale Harbor cache must
// never silently survive a clinical-content correction or privacy fix.
const CACHE_PREFIX = "harbor-shell-";
const CACHE_NAME = "harbor-shell-0.1.0-alpha.25";
const STAGING_SUFFIX = "-installing";
const STAGING_CACHE_NAME = `${CACHE_NAME}${STAGING_SUFFIX}`;

// The release finalizer replaces only the JSON value between these markers.
// An unfinalized build intentionally cannot install as an offline release.
const RELEASE_ASSETS =
  /* HARBOR_RELEASE_ASSETS_START */
  []
  /* HARBOR_RELEASE_ASSETS_END */;

function bytesToHex(bytes) {
  return Array.from(new Uint8Array(bytes), (byte) =>
    byte.toString(16).padStart(2, "0"),
  ).join("");
}

async function verifyReleaseResponse(asset, response) {
  if (!response.ok) {
    throw new Error("Harbor received an unavailable release asset.");
  }
  const body = await response.arrayBuffer();
  if (body.byteLength !== asset.bytes) {
    throw new Error("Harbor received an incomplete release asset.");
  }
  const digest = bytesToHex(await crypto.subtle.digest("SHA-256", body));
  if (digest !== asset.sha256) {
    throw new Error("Harbor received a corrupt release asset.");
  }
  return new Response(body, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
  });
}

function releaseAssetForRequest(request, navigation = false) {
  if (navigation) {
    return RELEASE_ASSETS.find((asset) => asset.url === "./index.html");
  }
  const requestUrl = new URL(request.url);
  const scopePath = new URL(self.registration.scope).pathname;
  if (!requestUrl.pathname.startsWith(scopePath)) return undefined;
  const relativePath = `./${requestUrl.pathname.slice(scopePath.length)}`;
  const exactUrl = `${relativePath}${requestUrl.search}`;
  return (
    RELEASE_ASSETS.find((asset) => asset.url === exactUrl) ||
    RELEASE_ASSETS.find((asset) => asset.url === relativePath)
  );
}

async function completedReleaseCacheNames() {
  return (await caches.keys())
    .filter(
      (name) =>
        name.startsWith(CACHE_PREFIX) &&
        !name.endsWith(STAGING_SUFFIX) &&
        name !== CACHE_NAME,
    )
    .reverse();
}

async function matchPreviousRelease(request) {
  for (const name of await completedReleaseCacheNames()) {
    const response = await (await caches.open(name)).match(request);
    if (response) return response;
  }
  return undefined;
}

self.addEventListener("install", (event) => {
  event.waitUntil(
    (async () => {
      if (RELEASE_ASSETS.length === 0) {
        throw new Error("Harbor's web release was not finalized.");
      }
      await Promise.all([
        caches.delete(STAGING_CACHE_NAME),
        caches.delete(CACHE_NAME),
      ]);
      try {
        const staging = await caches.open(STAGING_CACHE_NAME);
        const precacheAssets = RELEASE_ASSETS.filter(
          (asset) => asset.precache,
        );
        for (const asset of precacheAssets) {
          const request = new Request(asset.url, { cache: "reload" });
          const verified = await verifyReleaseResponse(
            asset,
            await fetch(request),
          );
          await staging.put(asset.url, verified);
        }

        const release = await caches.open(CACHE_NAME);
        for (const asset of precacheAssets) {
          const verified = await staging.match(asset.url);
          if (!verified) {
            throw new Error("Harbor's staged release is incomplete.");
          }
          await release.put(asset.url, verified);
        }
        await caches.delete(STAGING_CACHE_NAME);
        await self.skipWaiting();
      } catch (_) {
        await Promise.all([
          caches.delete(STAGING_CACHE_NAME),
          caches.delete(CACHE_NAME),
        ]);
        throw new Error("Harbor rejected an incomplete or corrupt update.");
      }
    })(),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      for (const name of await caches.keys()) {
        if (name.startsWith(CACHE_PREFIX) && name.endsWith(STAGING_SUFFIX)) {
          await caches.delete(name);
        }
      }
      // Completed prior releases remain available for explicit, tested
      // rollback. Staging caches are never eligible as a fallback.
      await self.clients.claim();
    })(),
  );
});

self.addEventListener("fetch", (event) => {
  const requestUrl = new URL(event.request.url);
  if (
    event.request.method !== "GET" ||
    requestUrl.origin !== self.location.origin
  ) {
    return;
  }

  if (event.request.mode === "navigate") {
    event.respondWith(
      (async () => {
        const indexAsset = releaseAssetForRequest(event.request, true);
        try {
          if (!indexAsset) throw new Error("Harbor index metadata is missing.");
          const verified = await verifyReleaseResponse(
            indexAsset,
            await fetch(event.request),
          );
          const cache = await caches.open(CACHE_NAME);
          await cache.put("./index.html", verified.clone());
          return verified;
        } catch (_) {
          const current = await (
            await caches.open(CACHE_NAME)
          ).match("./index.html");
          return current || (await matchPreviousRelease("./index.html"));
        }
      })(),
    );
    return;
  }

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      const current = await cache.match(event.request);
      if (current) return current;
      try {
        const response = await fetch(event.request);
        const asset = releaseAssetForRequest(event.request);
        if (!asset) return response;
        const verified = await verifyReleaseResponse(asset, response);
        await cache.put(event.request, verified.clone());
        return verified;
      } catch (error) {
        const previous = await matchPreviousRelease(event.request);
        if (previous) return previous;
        throw error;
      }
    })(),
  );
});
