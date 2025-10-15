export function getCurrentLocation(options = {}) {
  const defaultOptions = {
    enableHighAccuracy: true,
    timeout: 10000,
    maximumAge: 300000,
  };

  const finalOptions = { ...defaultOptions, ...options };

  return new Promise((resolve, reject) => {
    if (!("geolocation" in navigator)) {
      reject(new Error("Geolocation not supported"));
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        resolve({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
        });
      },
      (error) => {
        reject(error);
      },
      finalOptions,
    );
  });
}

export function isLocationTrackingEnabled() {
  const storedPreference = localStorage.getItem("locationTrackingEnabled");
  return storedPreference === "true";
}

export function setLocationTrackingEnabled(enabled) {
  localStorage.setItem("locationTrackingEnabled", enabled ? "true" : "false");
}
