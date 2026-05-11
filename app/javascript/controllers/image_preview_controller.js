import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "image", "message"]

  connect() {
    this.update()
  }

  update() {
    const url = this.inputTarget.value.trim()

    if (!url) {
      this.previewTarget.hidden = true
      this.imageTarget.removeAttribute("src")
      this.messageTarget.textContent = ""
      return
    }

    this.previewTarget.hidden = false
    this.messageTarget.textContent = ""
    this.imageTarget.src = url
  }

  loaded() {
    this.messageTarget.textContent = ""
  }

  failed() {
    this.messageTarget.textContent = "Image preview could not load."
  }
}
