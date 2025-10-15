import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["latitude", "longitude", "form"];

  connect() {
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      this.captureLocation();
    }
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

  async addLocation(event) {
    const locationEnabled = this.isLocationTrackingEnabled();

    if (!locationEnabled) {
      return;
    }

    event.preventDefault();

    const form = event.target.closest("form");

    try {
      const location = await this.getCurrentLocation();

      const latInput = document.createElement("input");
      latInput.type = "hidden";
      latInput.name = "latitude";
      latInput.value = location.latitude;
      form.appendChild(latInput);

      const lonInput = document.createElement("input");
      lonInput.type = "hidden";
      lonInput.name = "longitude";
      lonInput.value = location.longitude;
      form.appendChild(lonInput);

      form.requestSubmit();
    } catch (error) {
      console.log("Could not get location:", error.message);
      form.requestSubmit();
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
