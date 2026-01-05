import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = ["content", "checkbox", "hiddenField"]

  toggle() {
    if (this.checkboxTarget.checked) {
      this.contentTarget.style.display = "block"
      this.hiddenFieldTarget.value = "true"
    } else {
      this.contentTarget.style.display = "none"
      this.hiddenFieldTarget.value = "false"
      // Clear the email field when hiding it
      const emailInput = this.contentTarget.querySelector('input[type="email"]')
      if (emailInput) {
        emailInput.value = ""
      }
    }
  }
}
