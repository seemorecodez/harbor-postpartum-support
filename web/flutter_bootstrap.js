{{flutter_js}}
{{flutter_build_config}}

const HARBOR_RELEASE = "0.1.0-alpha.20";

const startupShell = document.getElementById("harbor-startup");
const startupStatus = document.getElementById("harbor-startup-status");
const startupRetry = document.getElementById("harbor-startup-retry");

function setStartupStatus(message) {
  if (startupStatus) startupStatus.textContent = message;
}

function showStartupFailure() {
  if (startupShell) startupShell.classList.add("harbor-startup--failed");
  setStartupStatus(
    "Harbor could not open. Nothing you wrote was sent. Check your connection, then try again.",
  );
}

window.addEventListener(
  "flutter-first-frame",
  () => {
    if (!startupShell) return;
    startupShell.classList.add("harbor-startup--ready");
    setTimeout(() => startupShell.remove(), 180);
  },
  { once: true },
);

function retryHarbor() {
  window.location.reload();
}

if (startupRetry) {
  startupRetry.addEventListener("click", retryHarbor);
  startupRetry.addEventListener("keydown", (event) => {
    if (event.key !== "Enter" && event.key !== " ") return;
    event.preventDefault();
    retryHarbor();
  });
}

async function harborHostIsReachable() {
  const abort = new AbortController();
  const timeout = setTimeout(() => abort.abort(), 1500);
  try {
    const response = await fetch(
      `version.json?harbor_probe=${Date.now()}`,
      { cache: "no-store", signal: abort.signal },
    );
    return response.ok;
  } catch (_) {
    return false;
  } finally {
    clearTimeout(timeout);
  }
}

async function prepareHarborOfflineShell() {
  if (!("serviceWorker" in navigator)) return;

  const activeRelease = navigator.serviceWorker.controller
    ? new URL(navigator.serviceWorker.controller.scriptURL).searchParams.get("v")
    : null;
  if (activeRelease === HARBOR_RELEASE) return;
  if (navigator.onLine === false) return;
  if (navigator.serviceWorker.controller && !(await harborHostIsReachable())) {
    return;
  }

  setStartupStatus("Securing the latest offline copy…");

  const registration = await navigator.serviceWorker.register(
    `harbor_service_worker.js?v=${HARBOR_RELEASE}`,
    { updateViaCache: "none" },
  );
  await registration.update();

  const candidate = registration.installing || registration.waiting;
  if (candidate && candidate.state !== "activated") {
    await new Promise((resolve, reject) => {
      const timeout = setTimeout(
        () => reject(new Error("Harbor offline update timed out.")),
        15000,
      );
      candidate.addEventListener("statechange", () => {
        if (candidate.state === "activated") {
          clearTimeout(timeout);
          resolve();
        } else if (candidate.state === "redundant") {
          clearTimeout(timeout);
          reject(new Error("Harbor offline update was rejected."));
        }
      });
    });
  }
  await navigator.serviceWorker.ready;
}

async function startHarbor() {
  setStartupStatus("Checking your private offline copy…");
  try {
    await prepareHarborOfflineShell();
  } catch (error) {
    console.warn("Harbor could not refresh its offline shell.", error);
  }

  setStartupStatus("Opening Harbor…");
  try {
    await _flutter.loader.load({
      config: {
        canvasKitBaseUrl: "canvaskit/",
        fontFallbackBaseUrl: "assets/fonts/",
        forceSingleThreadedSkwasm: true,
      },
    });
  } catch (error) {
    console.error("Harbor could not start.", error);
    showStartupFailure();
  }
}

startHarbor();
