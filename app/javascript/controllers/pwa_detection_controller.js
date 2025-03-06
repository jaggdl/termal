import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.detectPwaMode()
  }

  detectPwaMode() {
    // Check if the app is running in standalone mode (added to homescreen)
    const isStandalone = window.matchMedia('(display-mode: standalone)').matches ||
      window.navigator.standalone ||
      document.referrer.includes('android-app://');

    if (isStandalone) {
      document.documentElement.style.setProperty('--nav-b-padding', '2.5rem');
    } else {
      document.documentElement.style.setProperty('--nav-b-padding', '0.75rem');
    }
  }
}
