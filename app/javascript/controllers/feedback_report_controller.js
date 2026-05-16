import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "url",
    "viewportWidth",
    "viewportHeight",
    "screenWidth",
    "screenHeight",
    "timezone"
  ]

  connect() {
    this.captureMetadata()
  }

  captureMetadata() {
    if (this.hasUrlTarget) this.urlTarget.value = window.location.href
    if (this.hasViewportWidthTarget) this.viewportWidthTarget.value = window.innerWidth
    if (this.hasViewportHeightTarget) this.viewportHeightTarget.value = window.innerHeight
    if (this.hasScreenWidthTarget) this.screenWidthTarget.value = window.screen.width
    if (this.hasScreenHeightTarget) this.screenHeightTarget.value = window.screen.height
    if (this.hasTimezoneTarget) this.timezoneTarget.value = Intl.DateTimeFormat().resolvedOptions().timeZone
  }
}
