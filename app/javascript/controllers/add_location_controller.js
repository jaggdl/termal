import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["latitude", "longitude", "message"];

  async captureAndSubmit(event) {
    if (!("geolocation" in navigator)) {
      this.messageTarget.innerHTML = `
        <span class="text-red-600 dark:text-red-400">
          Location is not supported by your browser.
        </span>
      `;
      return;
    }

    this.messageTarget.innerHTML = `
      <span class="text-sky-600 dark:text-sky-400">
        Getting your location...
      </span>
    `;

    const form = event.target.closest("form");

    try {
      const location = await this.getCurrentLocation();
      this.latitudeTarget.value = location.latitude;
      this.longitudeTarget.value = location.longitude;

      const locationEnabled = this.isLocationTrackingEnabled();
      if (!locationEnabled) {
        localStorage.setItem("locationTrackingEnabled", "true");
      }

      form.requestSubmit();
    } catch (error) {
      console.log({ error, code: error.code, message: error.message });

      if (error.code === 1 || error.code === error.PERMISSION_DENIED) {
        this.messageTarget.innerHTML = `
          <span class="text-red-600 dark:text-red-400">
            Location permission denied. Please allow location access when your browser prompts you.
          </span>
        `;
      } else if (error.code === 3 || error.code === error.TIMEOUT) {
        this.messageTarget.innerHTML = `
          <span class="text-red-600 dark:text-red-400">
            Location request timed out. Please try again.
          </span>
        `;
      } else if (error.code === 2 || error.code === error.POSITION_UNAVAILABLE) {
        this.messageTarget.innerHTML = `
          <span class="text-red-600 dark:text-red-400">
            Location unavailable. Please check your device settings.
          </span>
        `;
      } else {
        this.messageTarget.innerHTML = `
          <span class="text-red-600 dark:text-red-400">
            Could not get location: ${error.message || "Unknown error"}
          </span>
        `;
      }
    }
  }

  getCurrentLocation() {
    return new Promise((resolve, reject) => {
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
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0,
        },
      );
    });
  }

  isLocationTrackingEnabled() {
    const storedPreference = localStorage.getItem("locationTrackingEnabled");
    return storedPreference === "true";
  }
}
