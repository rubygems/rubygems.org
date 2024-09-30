import { Application } from "@hotwired/stimulus"
import Clipboard from '@stimulus-components/clipboard'

const application = Application.start()

// Add vendored controllers
application.register('clipboard', Clipboard)

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
