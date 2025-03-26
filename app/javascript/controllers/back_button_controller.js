import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("click", this.goBack.bind(this))
  }

  goBack(event) {
    event.preventDefault()
    window.history.back()
  }
}