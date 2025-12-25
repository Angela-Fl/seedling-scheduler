import { Controller } from "@hotwired/stimulus"
import { Calendar } from '@fullcalendar/core'
import dayGridPlugin from '@fullcalendar/daygrid'
import multiMonthPlugin from '@fullcalendar/multimonth'
import interactionPlugin from '@fullcalendar/interaction'
import bootstrap5Plugin from '@fullcalendar/bootstrap5'
import { getTaskColor, getTaskDisplayName } from '../lib/task_colors'

export default class extends Controller {
  static values = {
    tasksUrl: String
  }
  static targets = ["calendar"]

  connect() {
    this.calendar = new Calendar(this.calendarTarget, {
      plugins: [dayGridPlugin, multiMonthPlugin, interactionPlugin, bootstrap5Plugin],
      themeSystem: 'bootstrap5',
      initialView: 'dayGridMonth',
      headerToolbar: {
        left: 'prev,next today',
        center: 'title',
        right: 'dayGridMonth,multiMonthYear'
      },
      height: 'auto',
      editable: true,
      selectable: true,
      dateClick: this.handleDateClick.bind(this),
      eventClick: this.handleEventClick.bind(this),
      eventDrop: this.handleEventDrop.bind(this),
      eventDidMount: this.handleEventDidMount.bind(this),
      datesSet: this.handleDatesSet.bind(this)
    })

    this.calendar.render()
    this.loadTasks()

    // Listen for reload events - bind to ensure proper context
    this.boundReloadHandler = () => {
      this.loadTasks()
    }
    window.addEventListener('calendar:reload', this.boundReloadHandler)
  }

  disconnect() {
    if (this.boundReloadHandler) {
      window.removeEventListener('calendar:reload', this.boundReloadHandler)
    }
    if (this.calendar) this.calendar.destroy()
  }

  async loadTasks(start = null, end = null) {
    if (!start || !end) {
      const now = new Date()
      start = new Date(now.getFullYear(), now.getMonth() - 1, 1)
      end = new Date(now.getFullYear(), now.getMonth() + 5, 0)
    }

    const url = new URL(this.tasksUrlValue, window.location.origin)
    url.searchParams.set('start', start.toISOString().split('T')[0])
    url.searchParams.set('end', end.toISOString().split('T')[0])

    try {
      const response = await fetch(url)
      const tasks = await response.json()

      this.calendar.removeAllEvents()
      tasks.forEach(task => this.calendar.addEvent(this.formatEvent(task)))
    } catch (error) {
      console.error('Failed to load tasks:', error)
    }
  }

  formatEvent(task) {
    let colors = getTaskColor(task.task_type)

    // Override colors based on status
    if (task.status === 'done') {
      colors = { bg: '#d3d3d3', text: '#000000' } // Light gray
    } else if (task.status === 'skipped') {
      colors = { bg: '#e8e8e8', text: '#000000' } // Even lighter gray
    }

    // Build title
    let title
    if (task.task_type === 'garden_task') {
      // For garden tasks, use notes as the title
      title = task.notes || 'Garden task'
    } else if (task.task_type === 'observe_sprouts') {
      // For sprout observation tasks, show as "Sprout window"
      title = 'Sprout window'
      if (task.plant_name) {
        title = `${title}: ${task.plant_name}`
      }
    } else {
      // For other tasks, show task type and plant name if present
      title = getTaskDisplayName(task.task_type)
      if (task.plant_name) {
        title = `${title}: ${task.plant_name}`
      }
    }

    // Add status symbol prefix
    if (task.status === 'done') {
      title = `✓ ${title}`
    } else if (task.status === 'skipped') {
      title = `⊘ ${title}`
    }

    const event = {
      id: task.id,
      title: title,
      start: task.due_date,
      allDay: true,
      backgroundColor: colors.bg,
      borderColor: colors.bg,
      textColor: colors.text,
      extendedProps: {
        taskType: task.task_type,
        plantName: task.plant_name,
        plantVariety: task.plant_variety,
        notes: task.notes,
        status: task.status,
        plantId: task.plant_id,
        dueDate: task.due_date
      }
    }

    // Add end date for multi-day events (FullCalendar uses exclusive end dates)
    if (task.end_date && task.end_date !== task.due_date) {
      const endDate = new Date(task.end_date)
      endDate.setDate(endDate.getDate() + 1) // FullCalendar end dates are exclusive
      event.end = endDate.toISOString().split('T')[0]
    }

    return event
  }

  handleDateClick(info) {
    window.dispatchEvent(new CustomEvent('calendar:create', {
      detail: { date: info.dateStr }
    }))
  }

  handleEventClick(info) {
    const { plantId } = info.event.extendedProps

    // If this is a plant task, navigate to the plant's page
    if (plantId) {
      window.location.href = `/plants/${plantId}`
    } else {
      // For general garden tasks, open the edit modal
      window.dispatchEvent(new CustomEvent('calendar:edit', {
        detail: {
          id: info.event.id,
          ...info.event.extendedProps
        }
      }))
    }
  }

  async handleEventDrop(info) {
    try {
      const response = await fetch(`/tasks/${info.event.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ task: { due_date: info.event.startStr } })
      })

      if (!response.ok) throw new Error('Update failed')
      this.showNotification('Task rescheduled', 'success')
    } catch (error) {
      info.revert()
      this.showNotification('Failed to reschedule', 'danger')
    }
  }

  handleEventDidMount(info) {
    const { plantName, plantVariety, notes, status } = info.event.extendedProps

    // Apply visual styling based on status
    if (status === 'done') {
      // Add strikethrough and italic for done tasks
      info.el.style.textDecoration = 'line-through'
      info.el.style.fontStyle = 'italic'
    } else if (status === 'skipped') {
      // Add italic for skipped tasks
      info.el.style.fontStyle = 'italic'
    }

    // Build tooltip content
    let content = ''
    if (plantName) {
      content += `<strong>${plantName}</strong> ${plantVariety ? `(${plantVariety})` : ''}<br>`
    } else {
      content += `<strong>General Garden Task</strong><br>`
    }
    if (notes) {
      content += `<small>${notes}</small><br>`
    }
    content += `<span class="badge bg-${status === 'done' ? 'success' : status === 'skipped' ? 'secondary' : 'warning'}">${status}</span>`

    new window.bootstrap.Tooltip(info.el, {
      title: content,
      html: true,
      placement: 'top'
    })
  }

  handleDatesSet(info) {
    this.loadTasks(info.start, info.end)
  }

  showNotification(message, type) {
    window.dispatchEvent(new CustomEvent('notification:show', {
      detail: { message, type }
    }))
  }
}
