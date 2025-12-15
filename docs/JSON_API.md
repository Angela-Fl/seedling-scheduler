# JSON API Reference

## Overview

Seedling Scheduler provides a RESTful JSON API for managing garden tasks. The API is primarily used by the interactive calendar view but is available for external integrations, mobile apps, or custom frontends.

**Base URL:** Same as your Rails app (e.g., `http://localhost:3000` in development)

**Authentication:** CSRF token required for mutating operations (POST, PATCH, DELETE)

**Content Type:** `application/json`

---

## Quick Start

### Fetching Tasks

```javascript
// Get all tasks for March 2025
const response = await fetch('/tasks.json?start=2025-03-01&end=2025-03-31')
const tasks = await response.json()
console.log(tasks)
```

### Creating a Task

```javascript
const csrfToken = document.querySelector('meta[name="csrf-token"]').content

const response = await fetch('/tasks', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({
    task: {
      task_type: 'garden_task',
      due_date: '2025-03-15',
      notes: 'Order compost and mulch',
      status: 'pending',
      plant_id: null
    }
  })
})

const task = await response.json()
```

---

## Authentication

### CSRF Token

Rails requires a CSRF token for all non-GET requests to prevent cross-site request forgery attacks.

**Get CSRF Token:**
```javascript
const csrfToken = document.querySelector('meta[name="csrf-token"]').content
```

**Include in Headers:**
```javascript
headers: {
  'X-CSRF-Token': csrfToken
}
```

**Where it comes from:**
```erb
<%# In app/views/layouts/application.html.erb %>
<%= csrf_meta_tags %>
```

Generates:
```html
<meta name="csrf-token" content="abc123def456...">
```

---

## Endpoints

## GET /tasks.json

Fetch tasks within a date range.

### Request

**Method:** `GET`

**URL:** `/tasks.json`

**Query Parameters:**
- `start` (optional): ISO date string (YYYY-MM-DD) - Start of date range
- `end` (optional): ISO date string (YYYY-MM-DD) - End of date range

**Example:**
```
GET /tasks.json?start=2025-03-01&end=2025-03-31
```

**Without date parameters:**
Returns tasks from the last 7 days onward (default behavior).

### Response

**Status:** `200 OK`

**Content-Type:** `application/json`

**Body:** Array of task objects

```json
[
  {
    "id": 1,
    "due_date": "2025-03-15",
    "task_type": "plant_seeds",
    "status": "pending",
    "notes": "Start tomatoes indoors in seed trays",
    "plant_id": 5,
    "plant_name": "Tomato",
    "plant_variety": "Cherry"
  },
  {
    "id": 2,
    "due_date": "2025-03-20",
    "task_type": "garden_task",
    "status": "pending",
    "notes": "Prepare raised beds with compost",
    "plant_id": null,
    "plant_name": null,
    "plant_variety": null
  },
  {
    "id": 3,
    "due_date": "2025-03-25",
    "task_type": "begin_hardening_off",
    "status": "done",
    "notes": "Move seedlings outdoors for a few hours",
    "plant_id": 5,
    "plant_name": "Tomato",
    "plant_variety": "Cherry"
  }
]
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `id` | Integer | Unique task identifier |
| `due_date` | String | ISO 8601 date (YYYY-MM-DD) |
| `task_type` | String | Type of task (see Task Types below) |
| `status` | String | Task status (pending, done, skipped) |
| `notes` | String or null | User notes/description |
| `plant_id` | Integer or null | Associated plant ID (null for garden tasks) |
| `plant_name` | String or null | Plant name (e.g., "Tomato") |
| `plant_variety` | String or null | Plant variety (e.g., "Cherry") |

### Task Types

| Value | Display Name | Description |
|-------|--------------|-------------|
| `plant_seeds` | Plant seeds | Start seeds indoors or outdoors |
| `begin_hardening_off` | Begin hardening off | Acclimate seedlings to outdoor conditions |
| `plant_seedlings` | Plant seedlings | Transplant seedlings to garden |
| `garden_task` | Garden task | General gardening task not tied to a specific plant |
| `begin_stratification` | Begin stratification | (Placeholder - not currently used) |

### Status Values

| Value | Display Name | Description |
|-------|--------------|-------------|
| `pending` | Pending | Task not yet completed |
| `done` | Done | Task completed |
| `skipped` | Skipped | Task skipped/not applicable |

### Examples

**Fetch tasks for a single month:**
```javascript
const start = '2025-03-01'
const end = '2025-03-31'
const response = await fetch(`/tasks.json?start=${start}&end=${end}`)
const tasks = await response.json()
```

**Fetch all tasks (last 7 days onward):**
```javascript
const response = await fetch('/tasks.json')
const tasks = await response.json()
```

**Fetch tasks for a year (calendar view):**
```javascript
const start = '2025-01-01'
const end = '2025-12-31'
const response = await fetch(`/tasks.json?start=${start}&end=${end}`)
const tasks = await response.json()
```

---

## POST /tasks

Create a new garden task.

### Request

**Method:** `POST`

**URL:** `/tasks`

**Headers:**
```
Content-Type: application/json
X-CSRF-Token: {csrf_token}
Accept: application/json
```

**Body:** Task object wrapped in `task` key

```json
{
  "task": {
    "task_type": "garden_task",
    "due_date": "2025-03-20",
    "notes": "Order seeds from catalog",
    "status": "pending",
    "plant_id": null
  }
}
```

### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task_type` | String | ✅ Yes | One of: plant_seeds, begin_hardening_off, plant_seedlings, garden_task |
| `due_date` | String | ✅ Yes | ISO date (YYYY-MM-DD) |
| `status` | String | ✅ Yes | One of: pending, done, skipped (usually "pending" for new tasks) |
| `notes` | String | No | Task description/notes |
| `plant_id` | Integer or null | No | Associated plant ID (null for garden_task) |

### Response (Success)

**Status:** `201 Created`

**Content-Type:** `application/json`

**Body:**
```json
{
  "id": 42,
  "due_date": "2025-03-20",
  "task_type": "garden_task",
  "status": "pending",
  "notes": "Order seeds from catalog",
  "plant_id": null,
  "plant_name": null,
  "plant_variety": null
}
```

### Response (Validation Error)

**Status:** `422 Unprocessable Entity`

**Body:**
```json
{
  "due_date": ["can't be blank"],
  "task_type": ["can't be blank"]
}
```

### Examples

**Create a garden task:**
```javascript
const csrfToken = document.querySelector('meta[name="csrf-token"]').content

const response = await fetch('/tasks', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({
    task: {
      task_type: 'garden_task',
      due_date: '2025-03-15',
      notes: 'Prepare raised beds',
      status: 'pending',
      plant_id: null
    }
  })
})

if (response.ok) {
  const task = await response.json()
  console.log('Created task:', task)
} else {
  const errors = await response.json()
  console.error('Validation errors:', errors)
}
```

**Create a plant-specific task:**
```javascript
const response = await fetch('/tasks', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({
    task: {
      task_type: 'plant_seeds',
      due_date: '2025-03-10',
      notes: 'Start indoors in seed trays',
      status: 'pending',
      plant_id: 5  // Associated with Tomato plant
    }
  })
})
```

---

## PATCH /tasks/:id

Update an existing task.

### Request

**Method:** `PATCH` or `PUT`

**URL:** `/tasks/{id}`

**Headers:**
```
Content-Type: application/json
X-CSRF-Token: {csrf_token}
Accept: application/json
```

**Body:** Partial task object (only include fields to update)

```json
{
  "task": {
    "due_date": "2025-03-25"
  }
}
```

### Request Fields

All fields are optional (only include what you want to change):

| Field | Type | Description |
|-------|------|-------------|
| `due_date` | String | New due date (YYYY-MM-DD) |
| `status` | String | New status (pending, done, skipped) |
| `notes` | String | Updated notes |
| `task_type` | String | Updated task type |
| `plant_id` | Integer or null | Updated plant association |

### Response (Success)

**Status:** `200 OK`

**Content-Type:** `application/json`

**Body:** Updated task object
```json
{
  "id": 42,
  "due_date": "2025-03-25",
  "task_type": "garden_task",
  "status": "pending",
  "notes": "Order seeds from catalog",
  "plant_id": null,
  "plant_name": null,
  "plant_variety": null
}
```

### Response (Not Found)

**Status:** `404 Not Found`

### Response (Validation Error)

**Status:** `422 Unprocessable Entity`

**Body:**
```json
{
  "due_date": ["can't be blank"]
}
```

### Examples

**Update due date (drag-and-drop on calendar):**
```javascript
const csrfToken = document.querySelector('meta[name="csrf-token"]').content
const taskId = 42
const newDate = '2025-03-25'

const response = await fetch(`/tasks/${taskId}`, {
  method: 'PATCH',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({
    task: {
      due_date: newDate
    }
  })
})

if (response.ok) {
  const updatedTask = await response.json()
  console.log('Updated task:', updatedTask)
}
```

**Mark task as done:**
```javascript
const response = await fetch(`/tasks/${taskId}`, {
  method: 'PATCH',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({
    task: {
      status: 'done'
    }
  })
})
```

**Update multiple fields:**
```javascript
const response = await fetch(`/tasks/${taskId}`, {
  method: 'PATCH',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({
    task: {
      due_date: '2025-03-25',
      status: 'done',
      notes: 'Completed ahead of schedule'
    }
  })
})
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | When it occurs |
|------|---------|----------------|
| `200 OK` | Success | Successful GET or PATCH |
| `201 Created` | Created | Successful POST |
| `404 Not Found` | Resource not found | Task ID doesn't exist |
| `422 Unprocessable Entity` | Validation error | Invalid data (missing required fields, invalid values) |
| `500 Internal Server Error` | Server error | Unexpected server issue |

### Error Response Format

**Validation Errors (422):**
```json
{
  "field_name": ["error message 1", "error message 2"],
  "another_field": ["error message"]
}
```

**Example:**
```json
{
  "due_date": ["can't be blank"],
  "task_type": ["is not included in the list"]
}
```

### Error Handling Pattern

```javascript
async function saveTask(taskData) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content

  try {
    const response = await fetch('/tasks', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({ task: taskData })
    })

    if (response.ok) {
      const task = await response.json()
      return { success: true, task }
    } else if (response.status === 422) {
      const errors = await response.json()
      return { success: false, errors }
    } else {
      const errorText = await response.text()
      return { success: false, error: errorText }
    }
  } catch (error) {
    console.error('Network error:', error)
    return { success: false, error: 'Network error occurred' }
  }
}

// Usage
const result = await saveTask({
  task_type: 'garden_task',
  due_date: '2025-03-15',
  notes: 'Test task',
  status: 'pending'
})

if (result.success) {
  console.log('Task created:', result.task)
} else {
  console.error('Failed:', result.errors || result.error)
}
```

---

## Integration with FullCalendar

The calendar view uses the JSON API to display and manage tasks.

### Fetching Events

```javascript
// In calendar_controller.js
async loadTasks() {
  const view = this.calendar.view
  const start = view.activeStart.toISOString().split('T')[0]
  const end = view.activeEnd.toISOString().split('T')[0]

  const response = await fetch(`/tasks.json?start=${start}&end=${end}`)
  const tasks = await response.json()

  // Convert to FullCalendar event format
  const events = tasks.map(task => ({
    id: task.id,
    title: getTaskDisplayName(task.task_type),
    start: task.due_date,
    backgroundColor: getTaskColor(task.task_type),
    extendedProps: {
      taskType: task.task_type,
      status: task.status,
      notes: task.notes,
      plantId: task.plant_id,
      plantName: task.plant_name,
      plantVariety: task.plant_variety
    }
  }))

  this.calendar.removeAllEvents()
  this.calendar.addEventSource(events)
}
```

### Updating on Drag-and-Drop

```javascript
async handleEventDrop(info) {
  const taskId = info.event.id
  const newDate = info.event.startStr

  const csrfToken = document.querySelector('meta[name="csrf-token"]').content

  const response = await fetch(`/tasks/${taskId}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify({
      task: { due_date: newDate }
    })
  })

  if (!response.ok) {
    // Revert if save failed
    info.revert()
    alert('Failed to update task date')
  }
}
```

### Creating from Date Click

```javascript
handleDateClick(info) {
  // Dispatch event for modal controller
  window.dispatchEvent(new CustomEvent('calendar:create', {
    detail: { date: info.dateStr }
  }))
}
```

---

## Use Cases

### 1. Mobile App Integration

Fetch upcoming tasks for mobile dashboard:

```javascript
// Get next 30 days of tasks
const today = new Date().toISOString().split('T')[0]
const thirtyDaysLater = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
  .toISOString().split('T')[0]

const response = await fetch(`/tasks.json?start=${today}&end=${thirtyDaysLater}`)
const upcomingTasks = await response.json()

// Filter pending tasks
const pendingTasks = upcomingTasks.filter(task => task.status === 'pending')

// Group by date
const tasksByDate = pendingTasks.reduce((acc, task) => {
  if (!acc[task.due_date]) acc[task.due_date] = []
  acc[task.due_date].push(task)
  return acc
}, {})
```

### 2. Bulk Status Updates

Mark multiple tasks as done:

```javascript
async function completeMultipleTasks(taskIds) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content

  const promises = taskIds.map(id =>
    fetch(`/tasks/${id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({
        task: { status: 'done' }
      })
    })
  )

  const results = await Promise.all(promises)
  const successful = results.filter(r => r.ok).length
  console.log(`Completed ${successful} of ${taskIds.length} tasks`)
}
```

### 3. Task Statistics

Calculate completion rate:

```javascript
async function getTaskStatistics(startDate, endDate) {
  const response = await fetch(`/tasks.json?start=${startDate}&end=${endDate}`)
  const tasks = await response.json()

  const total = tasks.length
  const completed = tasks.filter(t => t.status === 'done').length
  const pending = tasks.filter(t => t.status === 'pending').length
  const skipped = tasks.filter(t => t.status === 'skipped').length

  const completionRate = total > 0 ? (completed / total * 100).toFixed(1) : 0

  return {
    total,
    completed,
    pending,
    skipped,
    completionRate: `${completionRate}%`
  }
}

// Usage
const stats = await getTaskStatistics('2025-03-01', '2025-03-31')
console.log('March stats:', stats)
// { total: 25, completed: 18, pending: 5, skipped: 2, completionRate: "72.0%" }
```

### 4. Custom Dashboard Widget

```javascript
async function loadTaskWidget() {
  const response = await fetch('/tasks.json')
  const tasks = await response.json()

  // Get tasks due today
  const today = new Date().toISOString().split('T')[0]
  const todaysTasks = tasks.filter(t =>
    t.due_date === today && t.status === 'pending'
  )

  // Get overdue tasks
  const overdueTasks = tasks.filter(t =>
    t.due_date < today && t.status === 'pending'
  )

  // Display in widget
  document.querySelector('#today-count').textContent = todaysTasks.length
  document.querySelector('#overdue-count').textContent = overdueTasks.length
}
```

---

## Rate Limiting

**Current Status:** No rate limiting implemented

**Recommendations for production:**
- Implement rate limiting (e.g., Rack::Attack gem)
- Suggested limit: 100 requests per minute per IP
- Return `429 Too Many Requests` status when exceeded

---

## Future Enhancements

Potential API improvements for consideration:

### 1. Pagination

For large datasets:
```
GET /tasks.json?page=2&per_page=50
```

### 2. Filtering

```
GET /tasks.json?status=pending&task_type=garden_task
```

### 3. Sorting

```
GET /tasks.json?sort=due_date&order=desc
```

### 4. Plant Endpoints

```
GET /plants.json          # List all plants
GET /plants/:id.json      # Single plant with tasks
POST /plants              # Create plant
PATCH /plants/:id         # Update plant
DELETE /plants/:id        # Delete plant
```

### 5. Batch Operations

```
POST /tasks/batch
{
  "tasks": [
    { "task_type": "garden_task", "due_date": "2025-03-15", ... },
    { "task_type": "garden_task", "due_date": "2025-03-20", ... }
  ]
}
```

### 6. WebSocket Support

Real-time updates when tasks change (useful for collaborative editing):
```javascript
// Subscribe to task updates
const cable = ActionCable.createConsumer()
cable.subscriptions.create("TasksChannel", {
  received(data) {
    console.log("Task updated:", data)
    calendar.refetchEvents()
  }
})
```

---

## Testing the API

### Using curl

**Fetch tasks:**
```bash
curl "http://localhost:3000/tasks.json?start=2025-03-01&end=2025-03-31"
```

**Create task:**
```bash
curl -X POST http://localhost:3000/tasks \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: YOUR_CSRF_TOKEN" \
  -d '{"task":{"task_type":"garden_task","due_date":"2025-03-15","notes":"Test task","status":"pending","plant_id":null}}'
```

**Update task:**
```bash
curl -X PATCH http://localhost:3000/tasks/42 \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: YOUR_CSRF_TOKEN" \
  -d '{"task":{"status":"done"}}'
```

### Using Postman

1. **Set base URL:** `http://localhost:3000`
2. **Add CSRF token:**
   - Get token from browser: View page source → Find `<meta name="csrf-token">`
   - Add header: `X-CSRF-Token: {token_value}`
3. **Set Content-Type:** `application/json`
4. **Test endpoints:** GET, POST, PATCH

### Browser Console Testing

```javascript
// Open your app in browser
// Open DevTools console (F12)

// Fetch tasks
fetch('/tasks.json?start=2025-03-01&end=2025-03-31')
  .then(r => r.json())
  .then(console.log)

// Create task
const csrfToken = document.querySelector('meta[name="csrf-token"]').content
fetch('/tasks', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({
    task: {
      task_type: 'garden_task',
      due_date: '2025-03-15',
      notes: 'Test from console',
      status: 'pending',
      plant_id: null
    }
  })
})
  .then(r => r.json())
  .then(console.log)
```

---

## Resources

### Related Documentation
- [Stimulus Controllers Guide](STIMULUS_CONTROLLERS.md) - How the API is used in controllers
- [Vite Frontend Guide](VITE_FRONTEND.md) - Frontend architecture
- [Project Overview](../PROJECT_OVERVIEW.md) - Overall system design

### External Resources
- [Rails API Documentation](https://guides.rubyonrails.org/api_app.html)
- [FullCalendar Event Source](https://fullcalendar.io/docs/events-json-feed)
- [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API)

---

## Summary

The Seedling Scheduler JSON API provides simple, RESTful access to task data:

- **GET /tasks.json** - Fetch tasks by date range
- **POST /tasks** - Create new garden tasks
- **PATCH /tasks/:id** - Update task details

**Key Features:**
- 📅 Date range filtering for calendar integration
- 🔒 CSRF protection for security
- ✅ Validation with detailed error messages
- 🎯 Simple JSON format
- 📱 Ready for mobile app integration

**Common Use Cases:**
- Interactive calendar view (FullCalendar)
- Mobile app dashboards
- Task completion tracking
- Statistics and reporting
- Custom integrations

The API is currently internal-facing but designed to be extensible for future external integrations.
