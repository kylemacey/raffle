import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  loadConfigurationFields(event) {
    const productType = event.target.value
    const url = event.target.dataset.url

    fetch(`${url}?product_type=${productType}`, {
      headers: {
        'Accept': 'text/html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.text())
    .then(html => {
      document.getElementById('configuration-fields').innerHTML = html
    })
    .catch(error => {
      console.error('Error loading configuration fields:', error)
    })
  }
}