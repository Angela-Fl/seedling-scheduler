import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    window.addEventListener('notification:show', this.show.bind(this))
  }

  disconnect() {
    window.removeEventListener('notification:show', this.show.bind(this))
  }

  show(event) {
    const { message, type } = event.detail
    const alert = document.createElement('div')
    alert.className = `alert alert-${type} alert-dismissible fade show`
    alert.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `
    this.containerTarget.appendChild(alert)
    setTimeout(() => alert.remove(), 5000)
  }
}
