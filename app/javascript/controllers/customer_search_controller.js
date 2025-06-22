import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "email", "results"]

  connect() {
    this.search = this.search.bind(this)
    this.debouncedSearch = this.debounce(this.search, 500)
    document.addEventListener("click", this.handleDocumentClick.bind(this))
    this.highlightedIndex = -1
  }

  disconnect() {
    document.removeEventListener("click", this.handleDocumentClick.bind(this))
  }

  handleInput(event) {
    const query = event.target.value
    if (query.length < 3) {
      this.hideResults()
      return
    }
    this.debouncedSearch(query)
  }

  handleKeys(event) {
    const items = this.resultsTarget.querySelectorAll('a')
    if (items.length === 0) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.highlightedIndex = (this.highlightedIndex + 1) % items.length
      this.updateHighlight()
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.highlightedIndex = (this.highlightedIndex - 1 + items.length) % items.length
      this.updateHighlight()
    } else if (event.key === "Enter") {
      event.preventDefault()
      if (this.highlightedIndex >= 0) {
        items[this.highlightedIndex].click()
      }
    } else if (event.key === "Escape") {
      this.hideResults()
    }
  }

  async search(query) {
    try {
      const response = await fetch(`/pos/search_customers?query=${encodeURIComponent(query)}`)
      const customers = await response.json()
      this.renderResults(customers)
    } catch (error) {
      console.error("Failed to search customers:", error)
      this.hideResults()
    }
  }

  renderResults(customers) {
    this.highlightedIndex = -1
    if (customers.length === 0) {
      this.hideResults()
    } else {
      this.resultsTarget.innerHTML = customers.map(customer => `
        <a href="#" class="list-group-item list-group-item-action"
           data-action="click->customer-search#select"
           data-customer-name="${this.escapeHTML(customer.name)}"
           data-customer-email="${this.escapeHTML(customer.email)}">
          <strong>${this.escapeHTML(customer.name)}</strong><br>
          <small class="text-muted">${this.escapeHTML(customer.email)}</small>
        </a>
      `).join('')
      this.resultsTarget.classList.remove("d-none")
    }
  }

  updateHighlight() {
    const items = this.resultsTarget.querySelectorAll('a')
    items.forEach((item, index) => {
      if (index === this.highlightedIndex) {
        item.classList.add("active")
        item.scrollIntoView({ block: 'nearest' })
      } else {
        item.classList.remove("active")
      }
    })
  }

  select(event) {
    event.preventDefault()
    const target = event.currentTarget
    this.nameTarget.value = target.dataset.customerName
    this.emailTarget.value = target.dataset.customerEmail
    this.hideResults()
  }

  handleDocumentClick(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  hideResults() {
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.classList.add("d-none")
    this.highlightedIndex = -1
  }

  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }

  escapeHTML(str) {
    const p = document.createElement("p");
    p.appendChild(document.createTextNode(str));
    return p.innerHTML;
  }
}
