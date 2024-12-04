// I don't think this gets used in prod at all.

import { Application } from "@hotwired/stimulus"

// import PosController from "controllers/pos_controller";

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

application.register("pos", PosController);
application.register("winners", WinnersController);

export { application }
