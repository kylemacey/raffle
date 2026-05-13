import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "list"]
  static values = { options: Object }

  connect() {
    this.syncSelect()
  }

  add() {
    const type = this.selectTarget.value
    if (!type || this.selectedTypes().includes(type)) return

    this.listTarget.appendChild(this.buildChip(type))
    this.syncSelect()
  }

  remove(event) {
    event.currentTarget.closest("[data-payment-method-type]")?.remove()
    this.syncSelect()
  }

  selectedTypes() {
    return Array.from(this.listTarget.querySelectorAll("input[type='hidden']"))
      .map((input) => input.value)
      .filter(Boolean)
  }

  syncSelect() {
    const selected = new Set(this.selectedTypes())

    this.selectTarget.replaceChildren(this.placeholderOption())
    Object.entries(this.optionsValue).forEach(([type, label]) => {
      if (!selected.has(type)) {
        this.selectTarget.appendChild(this.option(type, label))
      }
    })
  }

  placeholderOption() {
    const option = document.createElement("option")
    option.value = ""
    option.textContent = "Add payment method type"
    return option
  }

  option(type, label) {
    const option = document.createElement("option")
    option.value = type
    option.textContent = label
    return option
  }

  buildChip(type) {
    const label = this.optionsValue[type] || type
    const chip = document.createElement("span")
    chip.className = "badge rounded-pill text-bg-secondary d-inline-flex align-items-center gap-2 py-2 px-3"
    chip.dataset.paymentMethodType = type

    const text = document.createElement("span")
    text.textContent = label

    const input = document.createElement("input")
    input.type = "hidden"
    input.name = "invoice_setting[payment_method_types][]"
    input.value = type

    const button = document.createElement("button")
    button.type = "button"
    button.className = "btn-close btn-close-white"
    button.ariaLabel = `Remove ${label}`
    button.dataset.action = "payment-method-types#remove"

    chip.append(text, input, button)
    return chip
  }
}
