import { Controller } from "@hotwired/stimulus";
import {
  getCurrentLocation,
  isLocationTrackingEnabled,
} from "utils/location_helper";

export default class extends Controller {
  static targets = ["latitude", "longitude", "form"];

  connect() {
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      this.captureLocation();
    }
  }

  async captureLocation() {
    if (!isLocationTrackingEnabled()) {
      return;
    }

    try {
      const location = await getCurrentLocation();
      this.latitudeTarget.value = location.latitude;
      this.longitudeTarget.value = location.longitude;
    } catch (error) {
      console.log("Could not get location:", error.message);
    }
  }

  async addLocation(event) {
    if (!isLocationTrackingEnabled()) {
      return;
    }

    event.preventDefault();

    const form = event.target.closest("form");

    try {
      const location = await getCurrentLocation();

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
}
