import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "completeCheckbox", "skipCheckbox", "statusBadge"]
  static values = {
    taskId: Number,
    status: String
  }

  connect() {
    this.updateRowAppearance()
  }

  async toggleComplete(event) {
    const checkbox = event.target
    const newStatus = checkbox.checked ? 'done' : 'pending'

    // Optimistic UI update
    const previousStatus = this.statusValue
    this.statusValue = newStatus
    this.updateRowAppearance()

    try {
      const endpoint = checkbox.checked ? 'complete' : 'reset'
      const response = await this.updateTaskStatus(endpoint)

      if (response.ok) {
        const data = await response.json()
        this.statusValue = data.status
        this.showNotification('Task updated', 'success')
      } else {
        throw new Error('Update failed')
      }
    } catch (error) {
      // Rollback on error
      this.statusValue = previousStatus
      checkbox.checked = !checkbox.checked
      this.updateRowAppearance()
      this.showNotification('Failed to update task', 'danger')
    }
  }

  async toggleSkip(event) {
    const checkbox = event.target
    const newStatus = checkbox.checked ? 'skipped' : 'pending'

    // Optimistic UI update
    const previousStatus = this.statusValue
    this.statusValue = newStatus
    this.updateRowAppearance()

    try {
      const endpoint = checkbox.checked ? 'skip' : 'reset'
      const response = await this.updateTaskStatus(endpoint)

      if (response.ok) {
        const data = await response.json()
        this.statusValue = data.status
        this.showNotification('Task updated', 'success')
      } else {
        throw new Error('Update failed')
      }
    } catch (error) {
      // Rollback on error
      this.statusValue = previousStatus
      checkbox.checked = !checkbox.checked
      this.updateRowAppearance()
      this.showNotification('Failed to update task', 'danger')
    }
  }

  async updateTaskStatus(action) {
    return fetch(`/tasks/${this.taskIdValue}/${action}`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    })
  }

  updateRowAppearance() {
    const row = this.rowTarget

    // Remove all status classes
    row.classList.remove('task-pending', 'task-done', 'task-skipped')

    // Add appropriate status class
    row.classList.add(`task-${this.statusValue}`)

    // Update checkboxes
    if (this.hasCompleteCheckboxTarget) {
      this.completeCheckboxTarget.checked = this.statusValue === 'done'
      this.skipCheckboxTarget.checked = this.statusValue === 'skipped'

      // Disable the other checkbox when one is checked
      this.completeCheckboxTarget.disabled = this.statusValue === 'skipped'
      this.skipCheckboxTarget.disabled = this.statusValue === 'done'
    }

    // Update status badge if present
    if (this.hasStatusBadgeTarget) {
      const badge = this.statusBadgeTarget
      badge.className = 'badge'

      switch(this.statusValue) {
        case 'done':
          badge.classList.add('bg-success')
          badge.textContent = 'Done'
          break
        case 'skipped':
          badge.classList.add('bg-secondary')
          badge.textContent = 'Skipped'
          break
        case 'pending':
          badge.classList.add('bg-warning')
          badge.textContent = 'Pending'
          break
      }
    }
  }

  showNotification(message, type) {
    window.dispatchEvent(new CustomEvent('notification:show', {
      detail: { message, type }
    }))
  }
}
