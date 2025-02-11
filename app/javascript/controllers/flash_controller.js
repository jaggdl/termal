import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["message"];

  close(event) {
    event.target.closest("div").remove();
  }
}
