import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "form",
    "input",
    "results",
    "clearButton",
    "loader",
    "searchIcon",
    "resultsContainer",
    "suggestions",
  ];
  static classes = ["loading"];

  connect() {
    this.timeout = null;
    this.blurTimeout = null;
  }

  search() {
    clearTimeout(this.timeout);

    if (!this.inputTarget.value.trim()) {
      this.showSuggestions();
      return;
    }

    this.hideSuggestions();
    this.showLoader();
    this.resultsContainerTarget.classList.remove("hidden");

    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit();
    }, 100);
  }

  focus() {
    clearTimeout(this.blurTimeout);
    if (!this.inputTarget.value.trim()) {
      this.showSuggestions();
    } else {
      this.resultsContainerTarget.classList.remove("hidden");
    }
  }

  blur() {
    this.blurTimeout = setTimeout(() => {
      this.resultsContainerTarget.classList.add("hidden");
    }, 200);
  }

  showSuggestions() {
    if (this.hasSuggestionsTarget) {
      this.resultsTarget.classList.add("hidden");
      this.suggestionsTarget.classList.remove("hidden");
      this.resultsContainerTarget.classList.remove("hidden");
    }
  }

  hideSuggestions() {
    if (this.hasSuggestionsTarget) {
      this.suggestionsTarget.classList.add("hidden");
      this.resultsTarget.classList.remove("hidden");
    }
  }

  clear() {
    this.inputTarget.value = "";
    this.toggleClearButton();
    this.showSuggestions();
  }

  clearResults() {
    this.resultsTarget.innerHTML = "";
    this.resultsContainerTarget.classList.add("hidden");
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

  showLoader() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.remove("hidden");
      this.searchIconTarget.classList.add("hidden");
    }
  }

  hideLoader() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.add("hidden");
      this.searchIconTarget.classList.remove("hidden");
    }
  }

  // Called when turbo:submit-start event is fired
  startSubmit(event) {
    // If the search input is empty, prevent the form submission and show suggestions instead
    if (!this.inputTarget.value.trim()) {
      event.preventDefault();
      this.showSuggestions();
      return;
    }

    this.showLoader();
  }

  // Called when turbo:submit-end event is fired
  endSubmit() {
    this.hideLoader();
  }
}
