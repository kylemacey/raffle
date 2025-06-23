import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "item" ]

  connect() {
    this.resizeItems();
    // Optional: Add a resize listener if you expect window resizing to affect card heights
    // window.addEventListener('resize', () => this.resizeItems());
  }

  resizeItems() {
    // Reset heights to auto to correctly calculate natural height
    this.itemTargets.forEach(item => {
      item.style.height = 'auto';
    });

    // Use requestAnimationFrame to ensure the 'auto' height has been applied
    // before we measure.
    requestAnimationFrame(() => {
      let maxHeight = 0;
      this.itemTargets.forEach(item => {
        if (item.offsetHeight > maxHeight) {
          maxHeight = item.offsetHeight;
        }
      });

      // Set all items to the max height
      this.itemTargets.forEach(item => {
        item.style.height = `${maxHeight}px`;
      });
    });
  }

  // Optional: disconnect lifecycle method to clean up event listeners
  // disconnect() {
  //   window.removeEventListener('resize', this.resizeItems);
  // }
}