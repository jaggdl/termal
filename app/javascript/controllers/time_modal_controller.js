import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "field"]

  open() {
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    this.fieldTarget.focus()
    requestAnimationFrame(() => this.fieldTarget.showPicker?.())
  }

  close() {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  disconnect() {
    document.body.style.overflow = ""
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }
}
