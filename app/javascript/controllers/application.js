import { Application } from "@hotwired/stimulus"
import Clipboard from '@stimulus-components/clipboard'
import CheckboxSelectAll from '@stimulus-components/checkbox-select-all'

const application = Application.start()

// Add vendored controllers
application.register('clipboard', Clipboard)
application.register('checkbox-select-all', CheckboxSelectAll)

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
