import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"];

  connect() {
    this.debounceTimeout = null;
  }

  disconnect() {
    clearTimeout(this.debounceTimeout);
  }

  submit() {
    clearTimeout(this.debounceTimeout);
    
    // Debounce to avoid rapid submissions when clicking multiple checkboxes quickly
    this.debounceTimeout = setTimeout(() => {
      this.formTarget.requestSubmit();
    }, 300);
  }

  // Select all meals
  selectAll() {
    this.checkboxes.forEach(checkbox => {
      checkbox.checked = true;
    });
    this.submit();
  }

  // Deselect all meals
  deselectAll() {
    this.checkboxes.forEach(checkbox => {
      checkbox.checked = false;
    });
    this.submit();
  }

  get checkboxes() {
    return this.element.querySelectorAll('input[type="checkbox"][name="selected_meal_ids[]"]');
  }
}
