import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    // Automatically called when the controller is connected to the page
    this.initRadioListeners();
    this.updateTotal();
  }

  updateTotal() {
    const selectedProduct = this.getSelectedProduct();
    const quantity = parseInt(document.getElementById("quantity").value) || 0;

    if (selectedProduct && quantity > 0) {
      const total = (selectedProduct.price * quantity) / 100; // Convert cents to dollars
      document.getElementById("total-amount").textContent = `$${total.toFixed(2)}`;
    } else {
      document.getElementById("total-amount").textContent = "$0.00";
    }
  }

  getSelectedProduct() {
    const selectedRadio = document.querySelector('input[name="product_id"]:checked');
    if (!selectedRadio) return null;

    const productId = selectedRadio.value;
    const productElement = selectedRadio.closest('.product');

    // Extract price from the product element
    const priceText = productElement.querySelector('.price').textContent;
    const price = parseFloat(priceText.replace(/[^0-9.]/g, '')) * 100; // Convert to cents

    return { id: productId, price: price };
  }

  initRadioListeners() {
    // Select all radio buttons with name 'product_id'
    const radioButtons = document.querySelectorAll('input[type="radio"][name="product_id"]');
    const quantityInput = document.getElementById("quantity");

    if (quantityInput) {
      // Add event listener to each radio button
      radioButtons.forEach((radio) => {
        radio.addEventListener("change", () => {
          this.updateTotal();
        });
      });

      // Add event listener to quantity input
      quantityInput.addEventListener("input", () => {
        this.updateTotal();
      });
    }
  }
}