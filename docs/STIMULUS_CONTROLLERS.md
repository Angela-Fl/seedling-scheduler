# Stimulus Controllers Guide

## Overview

Seedling Scheduler uses **Stimulus 3.2+** as its JavaScript framework for adding interactivity to HTML. Stimulus follows a "sprinkles of JavaScript" philosophy - it connects JavaScript behavior to HTML elements using data attributes, keeping your JavaScript organized and maintainable.

**Key Principles:**
- 📝 HTML first - markup defines structure and behavior
- 🎯 Modest JavaScript - only add interactivity where needed
- ♻️ Lifecycle awareness - connect/disconnect automatically managed
- 🔌 No build step required - works with Vite bundling

## Quick Reference

**Current Controllers:**
- `calendar_controller.js` - FullCalendar integration for task visualization
- `task-modal_controller.js` - Bootstrap modal for creating/editing garden tasks
- `notification_controller.js` - Toast notifications for user feedback

---

## Naming Conventions

### File Naming

**Format:** `descriptive-name_controller.js`
- Use **hyphens** for multi-word names (not underscores)
- End with `_controller.js` suffix
- Examples:
  - ✅ `task-modal_controller.js`
  - ✅ `calendar_controller.js`
  - ✅ `user-profile_controller.js`
  - ❌ `task_modal_controller.js` (no hyphens)
  - ❌ `taskmodal_controller.js` (no separator)

### Data Attribute Naming

**In HTML views:**
```erb
<%# Controller identifier: Use hyphens, matches filename (without _controller.js) %>
<div data-controller="task-modal">

<%# Targets: Use hyphens to match controller name %>
<form data-task-modal-target="form">
<input data-task-modal-target="dateInput">

<%# Actions: Format is event->controllerName#method %>
<button data-action="click->task-modal#submit">
<form data-action="submit->task-modal#submit">
</div>
```

**Common Mistake:**
```erb
<%# WRONG: Using underscores instead of hyphens %>
<div data-controller="task-modal">
  <form data-task_modal_target="form">  ❌ Wrong!
  <form data-task-modal_target="form">  ✅ Correct!
</div>
```

**Why it matters:**
- Stimulus converts naming automatically but inconsistency creates technical debt
- Hyphenated names are the official convention
- Code reviews will flag underscore usage

---

## Controller Structure

### Basic Template

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Define available targets
  static targets = ["output", "input"]

  // Define configurable values from HTML
  static values = {
    url: String,
    count: Number,
    enabled: Boolean
  }

  // Define CSS classes from HTML
  static classes = ["active", "hidden"]

  // Lifecycle: Called when controller is added to DOM
  connect() {
    console.log("Controller connected")
  }

  // Lifecycle: Called when controller is removed from DOM
  disconnect() {
    console.log("Controller disconnected")
    // IMPORTANT: Clean up event listeners, timers, etc.
  }

  // Action methods (called from HTML)
  handleClick(event) {
    console.log("Clicked!", event.target)
  }
}
```

### Lifecycle Methods

Stimulus automatically calls these methods:

```javascript
class extends Controller {
  // 1. Called once when controller is initialized
  initialize() {
    // Set up initial state
    this.counter = 0
  }

  // 2. Called when element enters the DOM (can be called multiple times with Turbo)
  connect() {
    // Add event listeners
    // Start timers
    // Initialize third-party libraries
  }

  // 3. Called when element leaves the DOM
  disconnect() {
    // Remove event listeners
    // Clear timers
    // Dispose of third-party library instances
  }

  // Called when target elements are added/removed
  [targetName]TargetConnected(element) { }
  [targetName]TargetDisconnected(element) { }

  // Called when value changes
  [valueName]ValueChanged(newValue, oldValue) { }
}
```

---

## Auto-Registration System

### How It Works

**File:** `app/frontend/controllers/index.js`

```javascript
// Auto-load all Stimulus controllers
export function registerControllers(application) {
  const controllers = import.meta.glob('./**/*_controller.js', { eager: true })

  for (const path in controllers) {
    const module = controllers[path]
    const name = path
      .replace(/^\.\//, '')                 // Remove leading ./
      .replace(/_controller\.js$/, '')      // Remove _controller.js suffix
      .replace(/\//g, '--')                 // Convert slashes to double hyphens

    application.register(name, module.default)
  }
}
```

**What this means:**
- All files ending in `_controller.js` are automatically registered
- File path becomes controller name
- Subdirectories supported via double-hyphen separator

**Examples:**
- `controllers/calendar_controller.js` → `data-controller="calendar"`
- `controllers/task-modal_controller.js` → `data-controller="task-modal"`
- `controllers/admin/user-settings_controller.js` → `data-controller="admin--user-settings"`

**Usage:**
```javascript
// In app/frontend/entrypoints/application.js
import { registerControllers } from "../controllers"

const application = Application.start()
registerControllers(application)
```

---

## Calendar Controller Deep Dive

**File:** `app/frontend/controllers/calendar_controller.js`

**Purpose:** Integrates FullCalendar library for interactive task calendar

### Key Features

**1. Configuration via HTML Values**
```erb
<div data-controller="calendar"
     data-calendar-tasks-url-value="<%= tasks_path(format: :json) %>">
  <div data-calendar-target="calendar"></div>
</div>
```

```javascript
static values = {
  tasksUrl: String  // Auto-converted from data-calendar-tasks-url-value
}
```

**2. Target Elements**
```javascript
static targets = ["calendar"]

connect() {
  // Access target via this.calendarTarget
  this.calendar = new Calendar(this.calendarTarget, options)
}
```

**3. Event Handlers**
```javascript
dateClick: this.handleDateClick.bind(this),
eventClick: this.handleEventClick.bind(this),
eventDrop: this.handleEventDrop.bind(this),
```

**4. Custom Event Communication**
```javascript
handleDateClick(info) {
  // Dispatch event for task-modal controller to listen
  window.dispatchEvent(new CustomEvent('calendar:create', {
    detail: { date: info.dateStr }
  }))
}
```

**5. Proper Event Listener Cleanup (✅ CORRECT PATTERN)**
```javascript
connect() {
  // Store bound reference
  this.boundReloadHandler = () => {
    this.loadTasks()
  }
  window.addEventListener('calendar:reload', this.boundReloadHandler)
}

disconnect() {
  // Remove using same reference
  if (this.boundReloadHandler) {
    window.removeEventListener('calendar:reload', this.boundReloadHandler)
  }
  if (this.calendar) this.calendar.destroy()
}
```

**Why this is correct:**
- `bind(this)` is called only once in `connect()`
- The bound function reference is stored in `this.boundReloadHandler`
- `disconnect()` removes the listener using the same reference
- Result: Event listener is properly removed, no memory leak

### Full Calendar Integration

```javascript
import { Calendar } from '@fullcalendar/core'
import dayGridPlugin from '@fullcalendar/daygrid'
import multiMonthPlugin from '@fullcalendar/multimonth'
import interactionPlugin from '@fullcalendar/interaction'
import bootstrap5Plugin from '@fullcalendar/bootstrap5'

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
    editable: true,         // Enable drag-and-drop
    selectable: true,       // Enable date selection
    dateClick: this.handleDateClick.bind(this),
    eventClick: this.handleEventClick.bind(this),
    eventDrop: this.handleEventDrop.bind(this),
    eventDidMount: this.handleEventDidMount.bind(this),
    datesSet: this.handleDatesSet.bind(this)
  })

  this.calendar.render()
  this.loadTasks()
}
```

### Loading Tasks via JSON API

```javascript
async loadTasks() {
  const view = this.calendar.view
  const start = view.activeStart.toISOString().split('T')[0]
  const end = view.activeEnd.toISOString().split('T')[0]

  const response = await fetch(`${this.tasksUrlValue}?start=${start}&end=${end}`)
  const tasks = await response.json()

  // Convert to FullCalendar event format
  const events = tasks.map(task => ({
    id: task.id,
    title: getTaskDisplayName(task.task_type),
    start: task.due_date,
    extendedProps: {
      taskType: task.task_type,
      status: task.status,
      notes: task.notes,
      plantId: task.plant_id
    }
  }))

  this.calendar.removeAllEvents()
  this.calendar.addEventSource(events)
}
```

---

## Task Modal Controller Deep Dive

**File:** `app/frontend/controllers/task-modal_controller.js`

**Purpose:** Manages Bootstrap modal for creating and editing garden tasks

### ⚠️ Current Memory Leak Issue

**PROBLEM (Lines 10-11, 15-16):**
```javascript
connect() {
  this.modal = new window.bootstrap.Modal(document.getElementById('taskModal'))

  // ❌ MEMORY LEAK: bind(this) creates new function reference
  window.addEventListener('calendar:create', this.handleCreate.bind(this))
  window.addEventListener('calendar:edit', this.handleEdit.bind(this))
}

disconnect() {
  // ❌ MEMORY LEAK: bind(this) creates DIFFERENT reference, won't match
  window.removeEventListener('calendar:create', this.handleCreate.bind(this))
  window.removeEventListener('calendar:edit', this.handleEdit.bind(this))
  if (this.modal) this.modal.dispose()
}
```

**Why this is broken:**
- `this.handleCreate.bind(this)` creates a **new function** each time
- The function reference in `addEventListener` is different from `removeEventListener`
- Result: Event listeners are never removed → memory leak
- Impact: Each Turbo navigation adds more listeners, accumulating over time

**CORRECT FIX:**
```javascript
connect() {
  this.modal = new window.bootstrap.Modal(document.getElementById('taskModal'))

  // ✅ Store bound references
  this.boundHandleCreate = this.handleCreate.bind(this)
  this.boundHandleEdit = this.handleEdit.bind(this)

  window.addEventListener('calendar:create', this.boundHandleCreate)
  window.addEventListener('calendar:edit', this.boundHandleEdit)
}

disconnect() {
  // ✅ Remove using same references
  if (this.boundHandleCreate) {
    window.removeEventListener('calendar:create', this.boundHandleCreate)
  }
  if (this.boundHandleEdit) {
    window.removeEventListener('calendar:edit', this.boundHandleEdit)
  }
  if (this.modal) this.modal.dispose()
}
```

### Targets

```javascript
static targets = ["form", "dateInput", "notesInput", "statusSelect"]

// Access in methods:
this.formTarget        // The <form> element
this.dateInputTarget   // The date input field
this.notesInputTarget  // The textarea
this.statusSelectTarget // The status select dropdown
```

### Creating Tasks

```javascript
handleCreate(event) {
  this.formTarget.reset()
  this.dateInputTarget.value = event.detail.date  // Prefill date from calendar
  this.formTarget.action = '/tasks'
  this.formTarget.querySelector('input[name="_method"]')?.remove()  // Remove PATCH override
  this.modal.show()
}
```

### Editing Tasks

```javascript
handleEdit(event) {
  const { id, notes, status, dueDate } = event.detail

  // Populate form fields
  this.dateInputTarget.value = dueDate
  this.notesInputTarget.value = notes || ''
  this.statusSelectTarget.value = status

  // Set form to PATCH mode
  this.formTarget.action = `/tasks/${id}`

  // Add method override for Rails
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
```

### AJAX Form Submission

```javascript
async submit(event) {
  event.preventDefault()

  const formData = new FormData(this.formTarget)
  const methodOverride = formData.get('_method')
  const method = methodOverride ? methodOverride.toUpperCase() : 'POST'

  // Convert FormData to JSON
  const data = {}
  formData.forEach((value, key) => {
    if (key !== '_method') {
      const fieldName = key.replace(/^task\[/, '').replace(/\]$/, '')
      data[fieldName] = value === '' && fieldName === 'plant_id' ? null : value
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

      // Notify calendar to reload
      window.dispatchEvent(new CustomEvent('calendar:reload'))

      // Show success notification
      window.dispatchEvent(new CustomEvent('notification:show', {
        detail: { message: 'Task saved successfully', type: 'success' }
      }))
    } else {
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
```

---

## Notification Controller Deep Dive

**File:** `app/frontend/controllers/notification_controller.js`

**Purpose:** Display toast notifications for user feedback

### ⚠️ Current Memory Leak Issue (Same Problem)

**PROBLEM (Lines 7, 11):**
```javascript
connect() {
  // ❌ MEMORY LEAK: Different function reference created
  window.addEventListener('notification:show', this.show.bind(this))
}

disconnect() {
  // ❌ MEMORY LEAK: Won't remove the listener
  window.removeEventListener('notification:show', this.show.bind(this))
}
```

**CORRECT FIX:**
```javascript
connect() {
  // ✅ Store bound reference
  this.boundShowHandler = this.show.bind(this)
  window.addEventListener('notification:show', this.boundShowHandler)
}

disconnect() {
  // ✅ Remove using same reference
  if (this.boundShowHandler) {
    window.removeEventListener('notification:show', this.boundShowHandler)
  }
}
```

### Showing Notifications

```javascript
show(event) {
  const { message, type } = event.detail
  const alert = document.createElement('div')
  alert.className = `alert alert-${type} alert-dismissible fade show`
  alert.innerHTML = `
    ${message}
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  `
  this.containerTarget.appendChild(alert)

  // Auto-dismiss after 5 seconds
  setTimeout(() => alert.remove(), 5000)
}
```

**Usage from other controllers:**
```javascript
window.dispatchEvent(new CustomEvent('notification:show', {
  detail: {
    message: 'Task saved successfully',
    type: 'success'  // success, danger, warning, info
  }
}))
```

---

## Event Communication Pattern

Stimulus controllers communicate via browser's native CustomEvent system:

### Dispatching Events

```javascript
// From calendar controller - notify that user clicked a date
window.dispatchEvent(new CustomEvent('calendar:create', {
  detail: { date: '2025-03-15' }
}))

// From task-modal controller - notify calendar to reload
window.dispatchEvent(new CustomEvent('calendar:reload'))

// From any controller - show notification
window.dispatchEvent(new CustomEvent('notification:show', {
  detail: { message: 'Success!', type: 'success' }
}))
```

### Listening for Events

```javascript
// Store bound reference
this.boundHandler = this.handleEvent.bind(this)
window.addEventListener('custom:event', this.boundHandler)
```

### Event Naming Convention

**Format:** `namespace:action`
- `calendar:create` - Create task from calendar
- `calendar:edit` - Edit task from calendar
- `calendar:reload` - Reload calendar events
- `notification:show` - Show notification toast

---

## Common Patterns

### 1. Working with Bootstrap Modals

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Initialize modal instance
    this.modal = new window.bootstrap.Modal(this.element)
  }

  disconnect() {
    // Dispose of modal to prevent memory leaks
    if (this.modal) {
      this.modal.dispose()
    }
  }

  open() {
    this.modal.show()
  }

  close() {
    this.modal.hide()
  }
}
```

### 2. AJAX Requests with CSRF Token

```javascript
async save() {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content

  const response = await fetch('/api/endpoint', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify({ data: 'value' })
  })

  if (response.ok) {
    const data = await response.json()
    // Handle success
  }
}
```

### 3. Debouncing User Input

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = null
  }

  disconnect() {
    // Clear pending timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  search(event) {
    // Clear previous timeout
    clearTimeout(this.timeout)

    // Debounce: Wait 300ms after user stops typing
    this.timeout = setTimeout(() => {
      this.performSearch(event.target.value)
    }, 300)
  }

  async performSearch(query) {
    const response = await fetch(`/search?q=${query}`)
    const results = await response.json()
    // Display results
  }
}
```

### 4. Animation with Targets

```javascript
export default class extends Controller {
  static targets = ["item"]
  static classes = ["hidden", "visible"]

  toggle() {
    this.itemTargets.forEach(item => {
      item.classList.toggle(this.hiddenClass)
      item.classList.toggle(this.visibleClass)
    })
  }
}
```

```erb
<div data-controller="toggle"
     data-toggle-hidden-class="d-none"
     data-toggle-visible-class="d-block">
  <button data-action="toggle#toggle">Toggle Items</button>
  <div data-toggle-target="item">Item 1</div>
  <div data-toggle-target="item">Item 2</div>
</div>
```

---

## Turbo Integration

### Understanding Turbo Drive

**What Turbo Does:**
- Intercepts link clicks and form submissions
- Fetches new page via AJAX
- Swaps `<body>` content without full page reload
- Result: Faster navigation, but page never truly "reloads"

**Impact on Stimulus:**
- Controllers disconnect when their elements are removed
- Controllers reconnect when navigated back (via Turbo cache)
- Must clean up properly in `disconnect()`

### Turbo Events

```javascript
// Listen for Turbo navigation events
document.addEventListener('turbo:load', () => {
  // Page has fully loaded (initial load or navigation)
  console.log('Page loaded')
})

document.addEventListener('turbo:before-cache', () => {
  // About to cache current page before navigating away
  // Clean up any UI state (e.g., close modals, clear forms)
})

document.addEventListener('turbo:render', () => {
  // Page has been rendered from cache or server
})
```

### Bootstrap Modal + Turbo Issue

**Problem:** Modal backdrops can persist after navigation

**Solution:**
```javascript
// In application.js or modal controller
document.addEventListener('turbo:before-cache', () => {
  // Remove any lingering modal backdrops
  document.querySelectorAll('.modal-backdrop').forEach(el => el.remove())

  // Hide any open modals
  document.querySelectorAll('.modal.show').forEach(el => {
    const modal = bootstrap.Modal.getInstance(el)
    if (modal) modal.hide()
  })
})
```

### Reinitializing Libraries

Some libraries need reinitialization after Turbo navigation:

```javascript
// In application.js
document.addEventListener('turbo:load', () => {
  // Reinitialize Bootstrap tooltips
  const tooltips = [...document.querySelectorAll('[data-bs-toggle="tooltip"]')]
  tooltips.forEach(el => new bootstrap.Tooltip(el))

  // Reinitialize popovers
  const popovers = [...document.querySelectorAll('[data-bs-toggle="popover"]')]
  popovers.forEach(el => new bootstrap.Popover(el))
})
```

---

## Creating New Controllers

### Step 1: Create Controller File

```bash
touch app/frontend/controllers/my-feature_controller.js
```

### Step 2: Write Controller Class

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static values = { name: String }

  connect() {
    console.log("My feature controller connected")
  }

  greet() {
    this.outputTarget.textContent = `Hello, ${this.nameValue}!`
  }
}
```

### Step 3: Add to HTML

```erb
<div data-controller="my-feature" data-my-feature-name-value="World">
  <button data-action="click->my-feature#greet">Greet</button>
  <div data-my-feature-target="output"></div>
</div>
```

### Step 4: Test

Controller is automatically registered! No manual registration needed.

---

## Best Practices

### 1. Always Clean Up in disconnect()

```javascript
disconnect() {
  // Remove event listeners
  if (this.boundHandler) {
    window.removeEventListener('event', this.boundHandler)
  }

  // Clear timers
  if (this.timeout) clearTimeout(this.timeout)
  if (this.interval) clearInterval(this.interval)

  // Dispose of third-party libraries
  if (this.chart) this.chart.destroy()
  if (this.modal) this.modal.dispose()
}
```

### 2. Use Bound References for Event Listeners

```javascript
// ✅ GOOD: Store bound reference
connect() {
  this.boundHandler = this.handleEvent.bind(this)
  element.addEventListener('click', this.boundHandler)
}
disconnect() {
  element.removeEventListener('click', this.boundHandler)
}

// ❌ BAD: Inline bind() prevents cleanup
connect() {
  element.addEventListener('click', this.handleEvent.bind(this))
}
disconnect() {
  // This won't work - different function reference!
  element.removeEventListener('click', this.handleEvent.bind(this))
}
```

### 3. Use Targets Instead of querySelector

```javascript
// ✅ GOOD: Use targets
static targets = ["output"]
this.outputTarget.textContent = "Hello"

// ❌ BAD: Manual query selectors
document.querySelector('#output').textContent = "Hello"
```

**Why targets are better:**
- Scoped to controller element
- Automatic error handling
- Better performance
- Clearer intent

### 4. Use Values for Configuration

```javascript
// ✅ GOOD: Use values
static values = { url: String, count: Number }
fetch(this.urlValue)

// ❌ BAD: Hard-code or use dataset
fetch('/api/endpoint')
fetch(this.element.dataset.url)
```

### 5. Keep Controllers Focused

**One responsibility per controller:**
- ✅ `calendar_controller.js` - Manages calendar only
- ✅ `task-modal_controller.js` - Manages modal only
- ❌ `tasks_controller.js` - Don't combine unrelated features

### 6. Use CustomEvents for Communication

```javascript
// ✅ GOOD: Loose coupling via events
window.dispatchEvent(new CustomEvent('task:saved'))

// ❌ BAD: Direct controller access
const otherController = this.application.getControllerForElementAndIdentifier(element, 'calendar')
otherController.reload()
```

---

## Debugging

### Enable Stimulus Debug Mode

```javascript
// In application.js
const application = Application.start()
application.debug = true  // Logs controller lifecycle events
```

**Output:**
```
[Stimulus] calendar connected
[Stimulus] task-modal connected
[Stimulus] notification connected
```

### Inspect Controllers in Console

```javascript
// Get all controllers on an element
const element = document.querySelector('[data-controller="calendar"]')
element[Symbol.for('stimulus.controllers')]

// Get specific controller
const controller = this.application.getControllerForElementAndIdentifier(
  element,
  'calendar'
)
```

### Common Issues

**Issue: "Missing target element"**
- Target name doesn't match data attribute
- Check spelling: `dateInput` (camelCase) → `data-calendar-target="dateInput"`

**Issue: "Action not found"**
- Method name typo in controller or HTML
- Check: `data-action="click->calendar#handleClick"` matches `handleClick()` method

**Issue: "Controller not connecting"**
- File not ending in `_controller.js`
- Syntax error in controller file (check browser console)
- Element missing `data-controller` attribute

---

## Testing Controllers

### Manual Testing Checklist

- [ ] Controller connects on page load
- [ ] Targets are found and accessible
- [ ] Actions trigger correct methods
- [ ] Event listeners work correctly
- [ ] Controller disconnects on navigation
- [ ] Event listeners are removed on disconnect
- [ ] No console errors
- [ ] Works after Turbo navigation (navigate away and back)

### Automated Testing (Future)

Consider adding Stimulus controller tests:

```javascript
// Example with @stimulus/testing
import { CalendarController } from "../calendar_controller"

test("connects and renders calendar", () => {
  const controller = new CalendarController()
  controller.connect()

  expect(controller.calendar).toBeDefined()
})
```

---

## Resources

### Official Documentation
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
- [Stimulus Reference](https://stimulus.hotwired.dev/reference/controllers)
- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)

### Related Project Docs
- [Vite Frontend Guide](VITE_FRONTEND.md)
- [JSON API Reference](JSON_API.md)
- [Project Overview](../PROJECT_OVERVIEW.md)

---

## Summary

Stimulus provides a simple, powerful way to add JavaScript interactivity:

- **HTML first:** Define behavior in markup with data attributes
- **Modest JavaScript:** Only add interactivity where needed
- **Lifecycle aware:** Automatic connect/disconnect with proper cleanup
- **Event-driven:** Controllers communicate via CustomEvents
- **Maintainable:** Organized, testable, easy to understand

**Key Takeaways:**
1. Use hyphens in file names and data attributes
2. Always store bound function references for event listeners
3. Clean up properly in `disconnect()` to prevent memory leaks
4. Use CustomEvents for cross-controller communication
5. Let the auto-registration system handle controller loading

Follow these patterns and your Stimulus controllers will be performant, maintainable, and free of memory leaks!
