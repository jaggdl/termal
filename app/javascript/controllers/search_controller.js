import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "input", "suggestions"];

  connect() {
    this.timeout = null;
    this.focusedIndex = -1;
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
    this.resetFocus();
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
    this.formTarget.requestSubmit();
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
    switch (event.key) {
      case "Escape":
        this.setState("idle");
        this.inputTarget.blur();
        break;
      case "ArrowDown":
        event.preventDefault();
        this.focusNext();
        break;
      case "ArrowUp":
        event.preventDefault();
        this.focusPrevious();
        break;
      case "Enter":
        if (this.focusedIndex >= 0) {
          event.preventDefault();
          if (event.metaKey || event.ctrlKey) {
            this.addFocusedMeal();
          } else {
            this.goToFocusedMeal();
          }
        }
        break;
    }
  }

  get items() {
    return this.element.querySelectorAll("[data-search-item]");
  }

  focusNext() {
    const items = this.items;
    if (items.length === 0) return;

    this.clearFocus();
    this.focusedIndex = Math.min(this.focusedIndex + 1, items.length - 1);
    this.applyFocus();
  }

  focusPrevious() {
    const items = this.items;
    if (items.length === 0) return;

    this.clearFocus();
    this.focusedIndex = Math.max(this.focusedIndex - 1, 0);
    this.applyFocus();
  }

  clearFocus() {
    this.items.forEach((item) => delete item.dataset.focused);
  }

  applyFocus() {
    const items = this.items;
    if (this.focusedIndex >= 0 && this.focusedIndex < items.length) {
      const item = items[this.focusedIndex];
      item.dataset.focused = "";
      item.scrollIntoView({ block: "nearest" });
    }
  }

  resetFocus() {
    this.clearFocus();
    this.focusedIndex = -1;
  }

  goToFocusedMeal() {
    const items = this.items;
    if (this.focusedIndex >= 0 && this.focusedIndex < items.length) {
      const link = items[this.focusedIndex].querySelector("a");
      if (link) {
        link.click();
      }
    }
  }

  addFocusedMeal() {
    const items = this.items;
    if (this.focusedIndex >= 0 && this.focusedIndex < items.length) {
      const form = items[this.focusedIndex].querySelector("form");
      if (form) {
        form.requestSubmit();
      }
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
