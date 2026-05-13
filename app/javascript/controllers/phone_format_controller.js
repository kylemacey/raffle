import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  guard(event) {
    if (!event.data) return
    if (!/^[\d()\-\s]+$/.test(event.data)) {
      event.preventDefault()
      return
    }

    if (this.nextDigits(event.data).length > 10) event.preventDefault()
  }

  format() {
    const digits = this.digits(this.element.value)
    if (digits.length > 10) {
      this.element.setCustomValidity("Enter a 10-digit phone number")
      return
    }

    this.element.value = this.formatDigits(digits)
    this.element.setCustomValidity(digits.length === 0 || digits.length === 10 ? "" : "Enter a 10-digit phone number")
  }

  formatDigits(digits) {
    if (digits.length <= 3) return digits
    if (digits.length <= 6) return `(${digits.slice(0, 3)}) ${digits.slice(3)}`

    return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6)}`
  }

  nextDigits(input) {
    const value = this.element.value
    const selectionStart = this.element.selectionStart ?? value.length
    const selectionEnd = this.element.selectionEnd ?? selectionStart
    const nextValue = `${value.slice(0, selectionStart)}${input}${value.slice(selectionEnd)}`

    return this.digits(nextValue)
  }

  digits(value) {
    return value.replace(/\D/g, "")
  }
}
