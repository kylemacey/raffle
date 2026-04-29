import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Controller connected
  }

  initialize() {
    // Listen for stream render events
    document.addEventListener("turbo:before-stream-render", this.handleStreamRender.bind(this))
    document.addEventListener("turbo:stream-render", this.handleStreamRender.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.handleStreamRender.bind(this))
    document.removeEventListener("turbo:stream-render", this.handleStreamRender.bind(this))
  }

  handleStreamRender(event) {
    // Extract action and target from the turbo-stream element
    const turboStream = event.target
    const action = turboStream.getAttribute('action')
    const target = turboStream.getAttribute('target')

    // Check if this is a replace action on the redirect_target
    if (action === "replace" && target === "redirect_target") {
      const template = turboStream.firstElementChild

      // Try different ways to get the URL
      let url = template?.textContent?.trim()
      if (!url) {
        url = template?.innerText?.trim()
      }
      if (!url) {
        url = template?.innerHTML?.trim()
      }

      if (url) {
        event.preventDefault()

        // Clear cart if redirecting to success page
        if (url.includes('/pos/success/')) {
          localStorage.removeItem('pos_cart')
        }

        window.Turbo.visit(url)
      }
    }
  }
}