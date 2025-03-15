import { Application } from "@hotwired/stimulus"

// Create and start Stimulus application
const application = Application.start()

// Configure Stimulus development experience
application.debug = true

// Make it available globally
window.Stimulus = application

console.log("Stimulus application initialized")

export { application }
