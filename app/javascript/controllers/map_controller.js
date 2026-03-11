import { Controller } from "@hotwired/stimulus";
import L from "leaflet";

export default class extends Controller {
  static targets = ["container"];
  static values = {
    latitude: Number,
    longitude: Number,
  };

  connect() {
    this.initializeMap();
    this.observer = new MutationObserver(() => this.updateMapTheme());
    this.observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["class"],
    });
  }

  disconnect() {
    if (this.map) {
      this.map.remove();
    }
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  initializeMap() {
    this.map = L.map(this.containerTarget, {
      zoomControl: true,
      scrollWheelZoom: false,
    }).setView([this.latitudeValue, this.longitudeValue], 15);

    this.updateMapTheme();

    L.marker([this.latitudeValue, this.longitudeValue]).addTo(this.map);
  }

  updateMapTheme() {
    if (!this.map) return;

    if (this.tileLayer) {
      this.map.removeLayer(this.tileLayer);
    }

    const isDark = document.documentElement.classList.contains("dark");

    if (isDark) {
      this.tileLayer = L.tileLayer(
        "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
        {
          attribution:
            '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
          subdomains: "abcd",
          maxZoom: 20,
        },
      ).addTo(this.map);
    } else {
      this.tileLayer = L.tileLayer(
        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        {
          attribution:
            '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
          maxZoom: 19,
        },
      ).addTo(this.map);
    }
  }
}
