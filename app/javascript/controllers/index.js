import { Application } from "@hotwired/stimulus"

import WinnersController from "controllers/winners_controller";
import PosProductFormController from "controllers/pos_product_form_controller";
import CartController from "controllers/cart_controller";
import RedirectController from "controllers/redirect_controller";

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

application.register("winners", WinnersController);
application.register("pos-product-form", PosProductFormController);
application.register("cart", CartController);
application.register("redirect", RedirectController);

export { application }
