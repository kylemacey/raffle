import { Application } from "@hotwired/stimulus"

import PosController from "controllers/pos_controller";
import WinnersController from "controllers/winners_controller";

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

application.register("pos", PosController);
application.register("winners", WinnersController);

export { application }
