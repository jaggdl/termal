import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["latitude", "longitude"];

  connect() {
    this.captureLocation();
  }

  async captureLocation() {
    const locationEnabled = this.isLocationTrackingEnabled();

    if (!locationEnabled) {
      return;
    }

    try {
      const location = await this.getCurrentLocation();
      this.latitudeTarget.value = location.latitude;
      this.longitudeTarget.value = location.longitude;
    } catch (error) {
      console.log("Could not get location:", error.message);
    }
  }

  getCurrentLocation() {
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
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 300000,
        },
      );
    });
  }

  isLocationTrackingEnabled() {
    const storedPreference = localStorage.getItem("locationTrackingEnabled");
    return storedPreference === "true";
  }
}
