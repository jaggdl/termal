import { Controller } from "@hotwired/stimulus";
import {
  getCurrentLocation,
  isLocationTrackingEnabled,
  setLocationTrackingEnabled,
} from "utils/location_helper";

export default class extends Controller {
  static targets = ["latitude", "longitude", "message"];

  async captureAndSubmit(event) {
    if (!("geolocation" in navigator)) {
      this.showError("Location is not supported by your browser.");
      return;
    }

    this.messageTarget.innerHTML = `
      <span class="text-sky-600 dark:text-sky-400">
        Getting your location...
      </span>
    `;

    const form = event.target.closest("form");

    try {
      const location = await getCurrentLocation({ maximumAge: 0 });
      this.latitudeTarget.value = location.latitude;
      this.longitudeTarget.value = location.longitude;

      if (!isLocationTrackingEnabled()) {
        setLocationTrackingEnabled(true);
      }

      form.requestSubmit();
    } catch (error) {
      console.log({ error, code: error.code, message: error.message });

      if (error.code === 1 || error.code === error.PERMISSION_DENIED) {
        this.showError(
          "Location permission denied. Please allow location access when your browser prompts you.",
        );
      } else if (error.code === 3 || error.code === error.TIMEOUT) {
        this.showError("Location request timed out. Please try again.");
      } else if (error.code === 2 || error.code === error.POSITION_UNAVAILABLE) {
        this.showError(
          "Location unavailable. Please check your device settings.",
        );
      } else {
        this.showError(
          `Could not get location: ${error.message || "Unknown error"}`,
        );
      }
    }
  }

  showError(message) {
    this.messageTarget.innerHTML = `
      <span class="text-red-600 dark:text-red-400">
        ${message}
      </span>
    `;
  }
}
