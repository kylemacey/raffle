import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    // Automatically called when the controller is connected to the page
    this.initRadioListeners();
  }

  requestTurboStream(event) {
    // Extract the tickets value from the input field
    const tickets = event.currentTarget.value;

    // Dynamically build the URL with the tickets value
    const url = `${event.currentTarget.dataset.url}?tickets=${tickets}`;

    fetch(url, {
      headers: { Accept: "text/vnd.turbo-stream.html" },
    })
      .then((response) => {
        if (response.ok) {
          return response.text();
        } else {
          throw new Error(`HTTP error! Status: ${response.status}`);
        }
      })
      .then((turboStream) => {
        Turbo.renderStreamMessage(turboStream);
      })
      .catch((error) => {
        console.error("Error fetching Turbo Stream:", error);
      });
  }

  initRadioListeners() {
    // Select all radio buttons with name 'product_tickets'
    const radioButtons = document.querySelectorAll('input[type="radio"][name="product_tickets"]');
    const customTicketsInput = document.getElementById("custom_tickets");

    if (customTicketsInput) {
      // Add event listener to each radio button
      radioButtons.forEach((radio) => {
        radio.addEventListener("change", (event) => {
          const selectedValue = event.target.value;

          // Update the custom tickets input field
          customTicketsInput.value = selectedValue;
          customTicketsInput.dispatchEvent(new Event("input", { bubbles: true }));
        });
      });
    }
  }
}