import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "results", "clearButton"];

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 300)
  }  // Show results when input is focused

  showResults() {
    this.resultsTarget.classList.add("focused");
  }

  // Hide results after a slight delay when input loses focus
  hideResults() {
    setTimeout(() => {
      this.resultsTarget.classList.remove("focused");
    }, 200);
  }

  // Clear the input and update the UI
  clear() {
    this.inputTarget.value = "";
    this.toggleClearButton();
    this.search();
  }

  // Toggle clear button visibility based on input value
  toggleClearButton() {
    if (this.inputTarget.value) {
      this.clearButtonTarget.style.display = "inline";
    } else {
      this.clearButtonTarget.style.display = "none";
    }
  }
}
