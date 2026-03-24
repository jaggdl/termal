import { Controller } from "@hotwired/stimulus";
import {
  getCurrentLocation,
  isLocationTrackingEnabled,
} from "utils/location_helper";

export default class extends Controller {
  connect() {
    this.setLocationCookie();
  }

  async setLocationCookie() {
    if (!isLocationTrackingEnabled()) {
      return;
    }

    try {
      const location = await getCurrentLocation();
      this.setCookie("user_latitude", location.latitude);
      this.setCookie("user_longitude", location.longitude);
    } catch (error) {
      console.log("Could not get location:", error.message);
    }
  }

  setCookie(name, value) {
    const expires = new Date();
    expires.setHours(expires.getHours() + 1); // 1 hour expiry
    document.cookie = `${name}=${value};expires=${expires.toUTCString()};path=/`;
  }
}
