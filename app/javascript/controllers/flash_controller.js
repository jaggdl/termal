import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["message"];

  connect() {
    setTimeout(() => {
      this.fadeOut();
    }, 5000);
  }

  close(event) {
    const flashElement = event.target.closest("[data-controller='flash']");
    this.fadeOut(flashElement);
  }

  fadeOut(element = this.element) {
    element.classList.add('transition-opacity', 'duration-300');

    element.style.opacity = '0';

    setTimeout(() => {
      element.remove();
    }, 300);
  }
}
