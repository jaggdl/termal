import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "results", "clearButton", "loader", "searchIcon", "normalSearchForm", "normalSearchInput", "normalSearchResults"];
  static classes = ["loading"];

  connect() {
    this.timeout = null;
    this.pendingRequest = null;
  }

  search() {
    clearTimeout(this.timeout);

    if (!this.inputTarget.value.trim()) {
      this.clearResults();
      this.hideLoader();
      return;
    }

    this.showLoader();


    this.normalSearchInputTarget.value = this.inputTarget.value;
    this.normalSearchFormTarget.requestSubmit();

    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit();
    }, 100);
  }

  clear() {
    this.inputTarget.value = "";
    this.toggleClearButton();
    this.clearResults();
    this.hideLoader();
  }

  clearResults() {
    this.resultsTarget.innerHTML = "";
    this.normalSearchResultsTarget.innerHTML = "";
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
    // If the search input is empty, prevent the form submission and clear results
    if (!this.inputTarget.value.trim()) {
      event.preventDefault();
      this.clearResults();
      this.hideLoader();
      return;
    }

    this.showLoader();
  }

  // Called when turbo:submit-end event is fired
  endSubmit() {
    this.hideLoader();
  }
}
