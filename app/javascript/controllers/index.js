import { application } from "controllers/application"

import CartController from "controllers/cart_controller"
application.register("cart", CartController)

import CustomerSearchController from "controllers/customer_search_controller"
application.register("customer-search", CustomerSearchController)

import PosProductFormController from "controllers/pos_product_form_controller"
application.register("pos-product-form", PosProductFormController)

import RedirectController from "controllers/redirect_controller"
application.register("redirect", RedirectController)

import WinnersController from "controllers/winners_controller"
application.register("winners", WinnersController)
