import { Application } from "@hotwired/stimulus"

import PosController from "pos_controller";

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

application.register("pos", PosController);

export { application }
