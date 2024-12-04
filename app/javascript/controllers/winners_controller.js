import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  remoteSubmit() {
    this.element.requestSubmit();
  }
}