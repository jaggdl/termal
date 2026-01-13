import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 300 } // 5 minutes in seconds
  }

  connect() {
    this.lastActiveAt = Date.now()
    this.handleVisibilityChange = this.handleVisibilityChange.bind(this)
    document.addEventListener("visibilitychange", this.handleVisibilityChange)
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.handleVisibilityChange)
  }

  handleVisibilityChange() {
    if (document.visibilityState === "visible") {
      const elapsedSeconds = (Date.now() - this.lastActiveAt) / 1000
      if (elapsedSeconds > this.thresholdValue) {
        Turbo.visit(window.location.href, { action: "replace" })
      }
    } else {
      this.lastActiveAt = Date.now()
    }
  }
}
