import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    this.sync()
  }

  sync() {
    const amount = Number.parseFloat(this.inputTarget.value)
    const label = Number.isFinite(amount) && amount > 0 ? this.formatCurrency(amount) : "your"

    this.submitTarget.value = `Place ${label} bid`
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: amount % 1 === 0 ? 0 : 2
    }).format(amount)
  }
}
