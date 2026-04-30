import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["items", "total", "checkoutButton", "cashPaymentMethod", "cardPaymentMethod", "cashPaymentLabelWrapper"]

  connect() {
    this.loadCart()
    this.updateDisplay()

    // Set up form submit handler
    const checkoutForm = document.getElementById('checkout-form');
    if (checkoutForm) {
      checkoutForm.addEventListener('submit', (e) => this.prepareCheckout(e));
    }
  }

  addToCart(event) {
    const productEl = event.currentTarget
    const productId = productEl.dataset.productId
    const isSubscription = productEl.dataset.isSubscription === 'true'
    const cart = this.getCart()

    if (isSubscription) {
      if (this.cartHasSubscription(cart)) {
        alert("Only one subscription may be purchased per order.")
        return;
      }
      if (cart[productId]) { // If it's already in the cart, don't increase quantity
        return;
      }
    }

    if (cart[productId]) {
      cart[productId] += 1
    } else {
      cart[productId] = 1
    }

    this.saveCart(cart)
    this.renderCart()
    this.updateDisplay()
  }

  updateQuantity(event) {
    const productId = event.currentTarget.dataset.productId
    const quantity = parseInt(event.currentTarget.value) || 0
    const cart = this.getCart()

    const productEl = document.querySelector(`[data-product-id='${productId}']`)
    if (productEl && productEl.dataset.isSubscription === 'true' && quantity > 1) {
      alert("Only one subscription may be purchased per order.")
      event.currentTarget.value = 1
      cart[productId] = 1
    } else if (quantity > 0) {
      cart[productId] = quantity
    } else {
      delete cart[productId]
    }

    this.saveCart(cart)
    this.renderCart()
    this.updateDisplay()
  }

  removeFromCart(event) {
    const productId = event.currentTarget.dataset.productId
    const cart = this.getCart()

    delete cart[productId]
    this.saveCart(cart)
    this.renderCart()
    this.updateDisplay()
  }

  clearCart() {
    localStorage.removeItem('pos_cart')
    this.renderCart()
    this.updateDisplay()
  }

  getCart() {
    const cartData = localStorage.getItem('pos_cart')
    return cartData ? JSON.parse(cartData) : {}
  }

  saveCart(cart) {
    localStorage.setItem('pos_cart', JSON.stringify(cart))
  }

  loadCart() {
    this.renderCart()
  }

  renderCart() {
    const cart = this.getCart()
    const cartItemsContainer = document.getElementById('cart-items')

    if (!cartItemsContainer) return

    if (Object.keys(cart).length === 0) {
      cartItemsContainer.innerHTML = '<p class="card-text text-center text-muted">Your cart is empty.</p>'
      this.updateTotal(0)
      this.updatePaymentOptions()
      return
    }

    let html = '<table class="table table-sm"><tbody>'
    let total = 0
    let requiresCard = false

    Object.keys(cart).forEach(productId => {
      const productEl = document.querySelector(`[data-product-id='${productId}']`)
      if (productEl) {
        const product = {
          id: productId,
          name: productEl.dataset.productName,
          price: parseInt(productEl.dataset.productPrice),
          isSubscription: productEl.dataset.isSubscription === 'true'
        }

        const quantity = cart[productId]
        const itemTotal = product.price * quantity
        total += itemTotal

        if (product.isSubscription) {
          requiresCard = true
        }

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
    cartItemsContainer.innerHTML = html

    this.updateTotal(total)
    this.updatePaymentOptions(requiresCard)
  }

  updateTotal(total) {
    const totalContainer = document.getElementById('cart-total')
    if (totalContainer) {
      totalContainer.innerHTML = `
        <div class="d-flex justify-content-between align-items-center">
          <h5 class="mb-0">Total:</h5>
          <h5 class="mb-0">$${(total / 100.0).toFixed(2)}</h5>
        </div>
      `
    }
  }

  updatePaymentOptions(requiresCard = false) {
    if (!this.hasCashPaymentMethodTarget || !this.hasCashPaymentLabelWrapperTarget) return;

    const wrapper = this.cashPaymentLabelWrapperTarget;

    if (requiresCard) {
      this.cashPaymentMethodTarget.disabled = true
      this.cardPaymentMethodTarget.checked = true
      wrapper.setAttribute('data-tooltip', "Roc Star purchases can't be made with cash")
    } else {
      this.cashPaymentMethodTarget.disabled = false
      wrapper.removeAttribute('data-tooltip')
    }
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
    const cart = this.getCart();
    const cartInput = document.createElement('input');
    cartInput.type = 'hidden';
    cartInput.name = 'cart_data';
    cartInput.value = JSON.stringify(cart);

    const checkoutForm = event.target;
    checkoutForm.appendChild(cartInput);
  }

  cartHasSubscription(cart) {
    for (const productId in cart) {
      const productEl = document.querySelector(`[data-product-id='${productId}']`)
      if (productEl && productEl.dataset.isSubscription === 'true') {
        return true
      }
    }
    return false
  }
}
