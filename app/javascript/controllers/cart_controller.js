import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["items", "total", "checkoutButton"]

  connect() {
    this.loadCart()
    this.updateDisplay()
    this.waitForProductsAndRender()

    // Set up form submit handler
    const checkoutForm = document.getElementById('checkout-form');
    if (checkoutForm) {
      checkoutForm.addEventListener('submit', (e) => this.prepareCheckout(e));
    }
  }

  addToCart(event) {
    const productId = event.currentTarget.dataset.productId
    const cart = this.getCart()

    if (cart[productId]) {
      cart[productId] += 1
    } else {
      cart[productId] = 1
    }

    this.saveCart(cart)
    this.updateDisplay()
    this.renderCart()
  }

  updateQuantity(event) {
    const productId = event.currentTarget.dataset.productId
    const quantity = parseInt(event.currentTarget.value) || 0
    const cart = this.getCart()

    if (quantity > 0) {
      cart[productId] = quantity
    } else {
      delete cart[productId]
    }

    this.saveCart(cart)
    this.updateDisplay()
    this.renderCart()
  }

  removeFromCart(event) {
    const productId = event.currentTarget.dataset.productId
    const cart = this.getCart()

    delete cart[productId]
    this.saveCart(cart)
    this.updateDisplay()
    this.renderCart()
  }

  clearCart() {
    localStorage.removeItem('pos_cart')
    this.updateDisplay()
    this.renderCart()
  }

  getCart() {
    const cartData = localStorage.getItem('pos_cart')
    return cartData ? JSON.parse(cartData) : {}
  }

  saveCart(cart) {
    localStorage.setItem('pos_cart', JSON.stringify(cart))
  }

  loadCart() {
    // This will be called by the server to populate initial data
    // The cart items are rendered server-side with data attributes
  }

  waitForProductsAndRender() {
    // Wait for products to be available, then render
    const checkProducts = () => {
      if (window.posProducts) {
        this.renderCart()
      } else {
        setTimeout(checkProducts, 10)
      }
    }
    checkProducts()
  }

  renderCart() {
    const cart = this.getCart()
    const products = window.posProducts || []
    const cartItemsContainer = document.getElementById('cart-items')

    if (!cartItemsContainer) return

    if (Object.keys(cart).length === 0) {
      cartItemsContainer.innerHTML = '<p class="card-text text-center text-muted">Your cart is empty.</p>'
      return
    }

    let html = '<table class="table table-sm"><tbody>'
    let total = 0

    Object.keys(cart).forEach(productId => {
      const product = products.find(p => p.id.toString() === productId)
      if (product) {
        const quantity = cart[productId]
        const itemTotal = product.price * quantity
        total += itemTotal

        html += `
          <tr>
            <td class="align-middle">
              ${product.name}<br>
              <small class="text-muted">$${(product.price / 100.0).toFixed(2)}</small>
            </td>
            <td class="align-middle" style="width: 90px;">
              <input type="number" value="${quantity}" min="0" class="form-control form-control-sm"
                     data-product-id="${productId}" data-action="input->cart#updateQuantity">
            </td>
            <td class="text-end align-middle" style="width: 120px;">
              $${(itemTotal / 100.0).toFixed(2)}
            </td>
            <td class="text-end align-middle" style="width: 60px;">
              <button type="button" class="btn btn-danger"
                      data-product-id="${productId}" data-action="click->cart#removeFromCart"
                      title="Remove item">
                &times;
              </button>
            </td>
          </tr>
        `
      }
    })

    html += '</tbody></table>'
    html += '<hr>'
    html += '<div class="d-flex justify-content-between align-items-center">'
    html += '<h5 class="mb-0">Total:</h5>'
    html += `<h5 class="mb-0">$${(total / 100.0).toFixed(2)}</h5>`
    html += '</div>'

    cartItemsContainer.innerHTML = html
  }

  updateDisplay() {
    const cart = this.getCart()
    const itemCount = Object.values(cart).reduce((sum, qty) => sum + qty, 0)

    // Update cart count badge if it exists
    const badge = document.querySelector('.cart-badge')
    if (badge) {
      badge.textContent = itemCount
      badge.style.display = itemCount > 0 ? 'inline' : 'none'
    }

    // Update checkout button state
    if (this.hasCheckoutButtonTarget) {
      this.checkoutButtonTarget.disabled = itemCount === 0
    }
  }

  // Called before checkout to prepare cart data
  prepareCheckout(event) {
    const cart = this.getCart()
    const cartInput = document.createElement('input')
    cartInput.type = 'hidden'
    cartInput.name = 'cart_data'
    cartInput.value = JSON.stringify(cart)

    const checkoutForm = event.target
    checkoutForm.appendChild(cartInput)
  }
}