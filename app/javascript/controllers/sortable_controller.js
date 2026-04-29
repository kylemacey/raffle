import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["list"]

  connect() {
    this.sortable = new Sortable(this.listTarget, {
      handle: "[data-sortable-handle]",
      animation: 150,
      onEnd: this.end.bind(this),
    })
  }

  disconnect() {
    this.sortable.destroy()
  }

  end(event) {
    const item = event.item
    const newIndex = event.newIndex
    const url = this.data.get("url")
    const id = item.dataset.id

    const formData = new FormData()
    formData.append("id", id)
    formData.append("priority", newIndex)

    fetch(url, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
      },
      body: formData,
    }).catch((error) => {
      console.error("Error updating priority:", error)
    })
  }
}