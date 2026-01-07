import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "dateInput", "notesInput", "statusSelect"]

  connect() {
    this.modal = new window.bootstrap.Modal(document.getElementById('taskModal'))

    // Listen for calendar events
    window.addEventListener('calendar:create', this.handleCreate.bind(this))
    window.addEventListener('calendar:edit', this.handleEdit.bind(this))
  }

  disconnect() {
    window.removeEventListener('calendar:create', this.handleCreate.bind(this))
    window.removeEventListener('calendar:edit', this.handleEdit.bind(this))
    if (this.modal) this.modal.dispose()
  }

  handleCreate(event) {
    this.formTarget.reset()
    this.dateInputTarget.value = event.detail.date
    this.formTarget.action = '/tasks'
    this.formTarget.querySelector('input[name="_method"]')?.remove()
    this.modal.show()
  }

  handleEdit(event) {
    const { id, notes, status, dueDate } = event.detail

    this.dateInputTarget.value = dueDate
    this.notesInputTarget.value = notes || ''
    this.statusSelectTarget.value = status

    // Set form action for update
    this.formTarget.action = `/tasks/${id}`

    // Add method override for PATCH
    let methodInput = this.formTarget.querySelector('input[name="_method"]')
    if (!methodInput) {
      methodInput = document.createElement('input')
      methodInput.type = 'hidden'
      methodInput.name = '_method'
      this.formTarget.appendChild(methodInput)
    }
    methodInput.value = 'patch'

    this.modal.show()
  }

  async submit(event) {
    event.preventDefault()

    const formData = new FormData(this.formTarget)
    const methodOverride = formData.get('_method')
    const method = methodOverride ? methodOverride.toUpperCase() : 'POST'

    // Convert FormData to JSON for cleaner Rails handling
    const data = {}
    formData.forEach((value, key) => {
      if (key !== '_method') {
        // Strip 'task[' prefix and ']' suffix from Rails form field names
        // e.g., 'task[due_date]' becomes 'due_date'
        const fieldName = key.replace(/^task\[/, '').replace(/\]$/, '')

        // Convert empty string to null for optional fields
        if (fieldName === 'plant_id' && value === '') {
          data[fieldName] = null
        } else {
          data[fieldName] = value
        }
      }
    })

    try {
      const response = await fetch(this.formTarget.action, {
        method: method,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ task: data })
      })

      if (response.ok) {
        this.modal.hide()

        // Trigger calendar reload if on calendar page
        window.dispatchEvent(new CustomEvent('calendar:reload'))

        // If on table view, reload the page
        if (!document.querySelector('[data-controller="calendar"]')) {
          window.location.reload()
        }

        window.dispatchEvent(new CustomEvent('notification:show', {
          detail: { message: 'Task saved successfully', type: 'success' }
        }))
      } else {
        // Get the actual error message from the server
        let errorMessage = 'Failed to save task'
        try {
          const errorData = await response.json()
          errorMessage = errorData.error || errorMessage
        } catch (e) {
          // If JSON parsing fails, try to get text
          const errorText = await response.text()
          console.error('Server error:', errorText)
        }
        window.dispatchEvent(new CustomEvent('notification:show', {
          detail: { message: errorMessage, type: 'danger' }
        }))
      }
    } catch (error) {
      console.error('Error saving task:', error)
      window.dispatchEvent(new CustomEvent('notification:show', {
        detail: { message: error.message || 'Error saving task', type: 'danger' }
      }))
    }
  }
}
