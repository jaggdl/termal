import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "input", "suggestions"];

  connect() {
    this.timeout = null;
    this.handleClickOutside = this.handleClickOutside.bind(this);
    document.addEventListener("click", this.handleClickOutside);
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside);
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.setState("idle");
    }
  }

  setState(state) {
    this.element.dataset.state = state;
  }

  updateHasValue() {
    if (this.inputTarget.value) {
      this.element.dataset.hasValue = "";
    } else {
      delete this.element.dataset.hasValue;
    }
  }

  search() {
    clearTimeout(this.timeout);
    this.updateHasValue();

    if (!this.inputTarget.value.trim()) {
      if (this.hasSuggestionsTarget) {
        this.setState("suggestions");
      }
      return;
    }

    this.setState("loading");

    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit();
    }, 100);
  }

  focus() {
    if (!this.inputTarget.value.trim()) {
      if (this.hasSuggestionsTarget) {
        this.setState("suggestions");
      }
    } else {
      this.setState("results");
    }
  }

  clear() {
    this.inputTarget.value = "";
    this.updateHasValue();
    this.setState("idle");
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.setState("idle");
      this.inputTarget.blur();
    }
  }

  // Called when turbo:submit-start event is fired
  startSubmit(event) {
    if (!this.inputTarget.value.trim()) {
      event.preventDefault();
      if (this.hasSuggestionsTarget) {
        this.setState("suggestions");
      }
      return;
    }
    this.setState("loading");
  }

  // Called when turbo:submit-end event is fired
  endSubmit() {
    if (!this.inputTarget.value.trim() && this.hasSuggestionsTarget) {
      this.setState("suggestions");
    } else {
      this.setState("results");
    }
  }
}
