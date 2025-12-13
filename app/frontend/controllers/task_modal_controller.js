import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "dateInput", "plantSelect", "taskTypeSelect"]

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
    const { id, taskType, plantId, notes, status, dueDate } = event.detail

    this.dateInputTarget.value = dueDate
    if (plantId) this.plantSelectTarget.value = plantId
    this.taskTypeSelectTarget.value = taskType

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
    const method = formData.get('_method') || 'POST'

    try {
      const response = await fetch(this.formTarget.action, {
        method: method,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: formData
      })

      if (response.ok) {
        this.modal.hide()
        // Trigger calendar reload
        window.dispatchEvent(new CustomEvent('calendar:reload'))
        window.dispatchEvent(new CustomEvent('notification:show', {
          detail: { message: 'Task saved successfully', type: 'success' }
        }))
      } else {
        const errors = await response.json()
        window.dispatchEvent(new CustomEvent('notification:show', {
          detail: { message: 'Failed to save task', type: 'danger' }
        }))
      }
    } catch (error) {
      console.error('Error saving task:', error)
      window.dispatchEvent(new CustomEvent('notification:show', {
        detail: { message: 'Error saving task', type: 'danger' }
      }))
    }
  }
}
