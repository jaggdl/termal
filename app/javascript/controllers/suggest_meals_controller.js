import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "buttonText", "loader", "icon"]

  connect() {
    this.originalText = this.buttonTextTarget.textContent
  }

  showLoading(event) {
    this.buttonTarget.disabled = true
    this.buttonTarget.classList.add("opacity-50", "cursor-not-allowed")
    this.buttonTextTarget.textContent = "Suggesting..."

    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.remove("hidden")
    }

    if (this.hasIconTarget) {
      this.iconTarget.classList.add("hidden")
    }
  }

  hideLoading() {
    this.buttonTarget.disabled = false
    this.buttonTarget.classList.remove("opacity-50", "cursor-not-allowed")
    this.buttonTextTarget.textContent = this.originalText

    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.add("hidden")
    }

    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("hidden")
    }
  }

  handleError() {
    this.hideLoading()
  }
}
