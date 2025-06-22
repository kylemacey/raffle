import { Application } from "@hotwired/stimulus"

import WinnersController from "./winners_controller";
import PosProductFormController from "controllers/pos_product_form_controller";
import CartController from "controllers/cart_controller";
import RedirectController from "./redirect_controller";
import CustomerSearchController from "./customer_search_controller"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

application.register("winners", WinnersController);
application.register("pos-product-form", PosProductFormController);
application.register("cart", CartController);
application.register("redirect", RedirectController);
application.register("customer-search", CustomerSearchController)

export { application }
