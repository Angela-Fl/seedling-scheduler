import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    plantId: Number,
    taskId: Number,
    taskType: String,
    notes: String,
    status: String,
    dueDate: String
  }

  handleClick(event) {
    // Don't navigate if clicking on the actions column or its children
    if (event.target.closest('td:first-child')) {
      return
    }

    if (this.hasPlantIdValue && this.plantIdValue) {
      window.location.href = `/plants/${this.plantIdValue}`
    } else {
      window.dispatchEvent(new CustomEvent('calendar:edit', {
        detail: {
          id: this.taskIdValue,
          taskType: this.taskTypeValue,
          plantId: this.hasPlantIdValue ? this.plantIdValue : null,
          notes: this.notesValue,
          status: this.statusValue,
          dueDate: this.dueDateValue
        }
      }))
    }
  }
}
