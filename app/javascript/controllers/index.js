import { application } from "controllers/application"

import CartController from "controllers/cart_controller"
application.register("cart", CartController)

import CustomerSearchController from "controllers/customer_search_controller"
application.register("customer-search", CustomerSearchController)

import BidAmountSubmitController from "controllers/bid_amount_submit_controller"
application.register("bid-amount-submit", BidAmountSubmitController)

import ImagePreviewController from "controllers/image_preview_controller"
application.register("image-preview", ImagePreviewController)

import PosProductFormController from "controllers/pos_product_form_controller"
application.register("pos-product-form", PosProductFormController)

import PhoneFormatController from "controllers/phone_format_controller"
application.register("phone-format", PhoneFormatController)

import RedirectController from "controllers/redirect_controller"
application.register("redirect", RedirectController)

import SortableController from "controllers/sortable_controller"
application.register("sortable", SortableController)

import WinnersController from "controllers/winners_controller"
application.register("winners", WinnersController)

import MatchHeightController from "controllers/match_height_controller"
application.register("match-height", MatchHeightController)

import PaymentMethodTypesController from "controllers/payment_method_types_controller"
application.register("payment-method-types", PaymentMethodTypesController)

import FeedbackReportController from "controllers/feedback_report_controller"
application.register("feedback-report", FeedbackReportController)
