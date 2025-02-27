import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "results", "clearButton"];

  connect() {
    this.timeout = null;
  }

  search() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit();
    }, 300);
  }

  clear() {
    this.inputTarget.value = "";
    this.toggleClearButton();
    this.search();
  }

  toggleClearButton() {
    if (this.inputTarget.value) {
      this.clearButtonTarget.classList.add("block");
      this.clearButtonTarget.classList.remove("hidden");
    } else {
      this.clearButtonTarget.classList.add("hidden");
      this.clearButtonTarget.classList.remove("block");
    }
  }
}
