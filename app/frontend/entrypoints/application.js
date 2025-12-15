// Import Turbo and Stimulus
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

// Import Bootstrap
import * as bootstrap from "bootstrap"

// Import controllers
import { registerControllers } from "../controllers"

// Import styles
import "../stylesheets/application.css"

// Initialize Stimulus
const application = Application.start()
application.debug = false
window.Stimulus = application

// Register all controllers
registerControllers(application)

// Make Bootstrap available globally
window.bootstrap = bootstrap

// Bootstrap auto-initialization
document.addEventListener("turbo:load", () => {
  // Initialize tooltips
  const tooltips = [...document.querySelectorAll('[data-bs-toggle="tooltip"]')]
  tooltips.forEach(el => new bootstrap.Tooltip(el))

  // Initialize popovers
  const popovers = [...document.querySelectorAll('[data-bs-toggle="popover"]')]
  popovers.forEach(el => new bootstrap.Popover(el))
})
