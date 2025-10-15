import { Controller } from "@hotwired/stimulus";
import {
  getCurrentLocation,
  isLocationTrackingEnabled,
  setLocationTrackingEnabled,
} from "utils/location_helper";

export default class extends Controller {
  static targets = ["checkbox", "status"];
  static values = { enabled: Boolean };

  connect() {
    this.checkLocationSupport();
    this.syncWithLocalStorage();
    this.updateStatus();
  }

  syncWithLocalStorage() {
    const storedValue = localStorage.getItem("locationTrackingEnabled");
    if (storedValue !== null) {
      const isEnabled = storedValue === "true";
      this.checkboxTarget.checked = isEnabled;
    }
  }

  checkLocationSupport() {
    if (!("geolocation" in navigator)) {
      this.statusTarget.textContent = "Location not supported by browser";
      this.statusTarget.classList.add("text-red-500");
      this.checkboxTarget.disabled = true;
      return false;
    }
    return true;
  }

  async toggleLocationTracking() {
    if (!this.checkLocationSupport()) {
      this.checkboxTarget.checked = false;
      return;
    }

    if (this.checkboxTarget.checked) {
      const permission = await this.requestLocationPermission();
      if (permission !== "granted") {
        this.checkboxTarget.checked = false;
        this.updateStatus("denied");
        return;
      }
      this.updateStatus("enabled");
      setLocationTrackingEnabled(true);
    } else {
      this.updateStatus("disabled");
      setLocationTrackingEnabled(false);
    }
  }

  async requestLocationPermission() {
    try {
      await getCurrentLocation({ timeout: 10000 });
      return "granted";
    } catch (error) {
      if (error.code === 1 || error.code === error.PERMISSION_DENIED) {
        return "denied";
      }
      return "error";
    }
  }

  updateStatus(status) {
    if (!this.hasStatusTarget) return;

    this.statusTarget.classList.remove(
      "text-green-500",
      "text-red-500",
      "text-gray-400",
    );

    if (status === "denied") {
      this.statusTarget.textContent = "Location permission denied";
      this.statusTarget.classList.add("text-red-500");
    } else if (status === "enabled") {
      this.statusTarget.textContent = "Location will be saved with meals";
      this.statusTarget.classList.add("text-green-500");
    } else if (status === "disabled") {
      this.statusTarget.textContent = "Location will not be tracked";
      this.statusTarget.classList.add("text-gray-400");
    } else {
      if (this.checkboxTarget.checked) {
        this.statusTarget.textContent = "Location will be saved with meals";
        this.statusTarget.classList.add("text-green-500");
      } else {
        this.statusTarget.textContent = "Location will not be tracked";
        this.statusTarget.classList.add("text-gray-400");
      }
    }
  }
}
