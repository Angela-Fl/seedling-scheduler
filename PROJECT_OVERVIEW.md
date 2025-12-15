# Seedling Scheduler - Project Overview

**Last Updated:** 2025-12-14
**Rails Version:** 8.1.1
**Ruby Version:** 3.3+
**Build Tool:** Vite 5.4

---

## Quick Summary

Seedling Scheduler is a Ruby on Rails web application that helps gardeners manage seed starting schedules based on their local last frost date. It automatically calculates when to start seeds indoors, begin hardening off seedlings, and transplant them outside.

---

## Core Architecture

### Tech Stack
- **Backend:** Rails 8.1, SQLite, Turbo Rails
- **Frontend:** Stimulus, Bootstrap 5, FullCalendar, Vite
- **Deployment:** Kamal, Docker-ready, Solid* adapters

### Directory Structure
```
app/
├── controllers/          # PlantsController, TasksController, SettingsController
├── models/              # Plant, Task, Setting
├── views/               # ERB templates
├── helpers/             # View helpers (badge colors, task formatting)
└── frontend/            # Vite-managed assets
    ├── controllers/     # Stimulus controllers (calendar, task-modal, notification)
    ├── entrypoints/     # application.js (main entry)
    ├── lib/             # task_colors.js (shared color definitions)
    └── stylesheets/     # application.css
```

---

## Data Models

### Plant (`app/models/plant.rb`)
Central model representing a plant to be grown.

**Key Attributes:**
- `name` (required) - Plant name
- `variety` - Specific variety
- `sowing_method` (enum, required):
  - `indoor_start` - Start seeds indoors, harden off, transplant
  - `direct_sow` - Sow directly in garden
  - `outdoor_start` - Winter sowing method
  - `fridge_stratify` - Future: cold stratification
- `plant_seeds_offset_days` - Days before/after frost to plant seeds
- `hardening_offset_days` - Days before/after frost to start hardening
- `plant_seedlings_offset_days` - Days before/after frost to transplant
- `notes` - Growing notes

**Relationships:**
- `has_many :tasks, dependent: :destroy`

**Key Methods:**
- `generate_tasks!(last_frost_date)` - Creates tasks based on sowing method

**Task Generation Logic:**
- `indoor_start`: Creates 3 tasks (plant seeds, harden off, transplant)
- `direct_sow`: Creates 1 task (plant seeds)
- `outdoor_start`: Creates 2 tasks (plant seeds, transplant)

---

### Task (`app/models/task.rb`)
Represents an actionable gardening task.

**Key Attributes:**
- `due_date` (required) - When task should be done
- `task_type` (enum, required):
  - `plant_seeds` - Sow seeds
  - `begin_hardening_off` - Start hardening
  - `plant_seedlings` - Transplant
  - `garden_task` - General task (not plant-specific)
- `status` (enum, required):
  - `pending` - Not done
  - `done` - Completed
  - `skipped` - Skipped
- `plant_id` (optional) - Associated plant
- `notes` - Additional details

**Relationships:**
- `belongs_to :plant, optional: true`

**Key Methods:**
- `display_name` - Human-friendly task type label
- `display_subject` - Full description including plant name

---

### Setting (`app/models/setting.rb`)
Key-value store for application settings.

**Key Methods:**
- `Setting.frost_date` - Returns configured last frost date (default: May 15, 2026)
- `Setting.set_frost_date(date)` - Updates frost date and regenerates all tasks

---

## Controllers

### PlantsController
**Purpose:** CRUD operations for plants

**Key Actions:**
- `index` - List all plants
- `show` - Plant details and associated tasks
- `new/create` - Create plant and auto-generate tasks
- `edit/update` - Update plant and regenerate tasks
- `destroy` - Delete plant and tasks
- `regenerate_tasks` - Manual task regeneration

**Important Logic:**
- Converts UI inputs (weeks/days before/after frost) to `offset_days` integers
- Negative offsets = before frost, positive = after frost

---

### TasksController
**Purpose:** Task viewing and updates

**Key Actions:**
- `index` - List tasks (HTML: table view from past 7 days; JSON: calendar API with date filtering)
- `create` - Create general garden task
- `update` - Update task (for drag-and-drop rescheduling)
- `calendar` - Interactive calendar view

**JSON API:**
```
GET /tasks.json?start=YYYY-MM-DD&end=YYYY-MM-DD
```
Returns tasks within date range for FullCalendar.

---

### SettingsController
**Purpose:** Manage frost date

**Key Actions:**
- `edit` - Frost date configuration form
- `update` - Update frost date and regenerate ALL tasks for ALL plants

---

## Frontend (Stimulus Controllers)

### calendar_controller.js
**Purpose:** Interactive FullCalendar view

**Features:**
- Day/month/year views
- Drag-and-drop task rescheduling (PATCH /tasks/:id)
- Click date to create new garden task
- Click event to view/edit task
- Color-coded events by task type
- Bootstrap 5 theming
- Tooltips with plant details

**Dependencies:** @fullcalendar/core, daygrid, multimonth, interaction, bootstrap5

---

### task-modal_controller.js
**Purpose:** Create/edit modal for general garden tasks

**Features:**
- Opens modal on calendar click
- Form submission via AJAX
- Triggers calendar reload after save
- Bootstrap modal integration

---

### notification_controller.js
**Purpose:** Toast-style notifications

**Features:**
- Listens for `notification:show` events
- Auto-dismisses after 5 seconds
- Bootstrap alert styling

---

### lib/task_colors.js
**Shared Color Scheme:**
- `plant_seeds` - Pink (#FFCBE1)
- `begin_hardening_off` - Yellow (#F9E1A8)
- `plant_seedlings` - Green (#D6E5BD)
- `garden_task` - Blue (#C9E4F5)

Consistent across Rails helpers and JavaScript.

---

## Key Features

### 1. Automatic Task Generation
Tasks calculated from frost date + plant-specific offsets. Updating frost date or plant timing regenerates tasks automatically.

### 2. Dual View Modes
- **Table View** (`/tasks`) - Sortable list from past 7 days onward
- **Calendar View** (`/tasks/calendar`) - Interactive FullCalendar with drag-and-drop

### 3. Flexible Sowing Methods
Different task generation based on how plants are started (indoor, direct sow, outdoor start).

### 4. General Garden Tasks
Tasks not tied to plants (e.g., "prepare beds", "order compost").

### 5. Color-Coded System
Visual cues throughout UI for quick task type identification.

---

## Build System

### Development
```bash
bin/dev  # Starts Rails + Vite dev server (Foreman)
```

### Production
```bash
bin/vite build
bin/rails server
```

### Vite Configuration
- **Config:** `vite.config.ts`
- **Source:** `app/frontend/`
- **Dev Server:** Port 3036
- **Integration:** vite-plugin-ruby

---

## Testing

### Structure
```
test/
├── controllers/     # HTTP response tests
├── models/         # Validations, business logic
├── helpers/        # View helper tests
├── integration/    # Workflow tests
└── system/         # Browser-based E2E tests
```

### CI/CD (GitHub Actions)
1. Security scans (Brakeman, Bundler Audit, npm audit)
2. Linting (RuboCop)
3. Unit tests
4. System tests (Capybara + Selenium)

---

## Important Business Logic

### Offset Days Calculation
- **UI:** Users enter "6 weeks before frost" or "2 days after frost"
- **Storage:** Converted to integer days (negative = before, positive = after)
- **Example:** 6 weeks before frost = -42 days

### Task Regeneration Strategy
- Destroys ALL existing tasks for a plant
- Recreates fresh tasks from current frost date + offsets
- Simple, predictable, no complex state management

### Frost Date Impact
- Changing frost date regenerates tasks for ALL plants
- Default: May 15, 2026
- Stored in `settings` table as key-value pair

---

## Common File Paths

### Models
- `/home/adminang/projects/seedling_scheduler/app/models/plant.rb`
- `/home/adminang/projects/seedling_scheduler/app/models/task.rb`
- `/home/adminang/projects/seedling_scheduler/app/models/setting.rb`

### Controllers
- `/home/adminang/projects/seedling_scheduler/app/controllers/plants_controller.rb`
- `/home/adminang/projects/seedling_scheduler/app/controllers/tasks_controller.rb`
- `/home/adminang/projects/seedling_scheduler/app/controllers/settings_controller.rb`

### Frontend
- `/home/adminang/projects/seedling_scheduler/app/frontend/controllers/calendar_controller.js`
- `/home/adminang/projects/seedling_scheduler/app/frontend/controllers/task-modal_controller.js`
- `/home/adminang/projects/seedling_scheduler/app/frontend/lib/task_colors.js`

### Views
- `/home/adminang/projects/seedling_scheduler/app/views/plants/`
- `/home/adminang/projects/seedling_scheduler/app/views/tasks/`
- `/home/adminang/projects/seedling_scheduler/app/views/tasks/calendar.html.erb`

### Config
- `/home/adminang/projects/seedling_scheduler/vite.config.ts`
- `/home/adminang/projects/seedling_scheduler/config/routes.rb`
- `/home/adminang/projects/seedling_scheduler/.node-version`

---

## Recent Changes (from git status)

**Modified:**
- `.gitignore`
- `app/frontend/controllers/calendar_controller.js`
- `app/frontend/lib/task_colors.js`
- `app/helpers/tasks_helper.rb`
- `app/models/task.rb`
- `app/views/plants/show.html.erb`
- `app/views/tasks/calendar.html.erb`
- `app/views/tasks/index.html.erb`

**Deleted:**
- `app/frontend/controllers/task_modal_controller.js` (wrong naming)

**Untracked:**
- `app/frontend/controllers/task-modal_controller.js` (correct naming with hyphen)

**Recent Commits:**
- Added calendar view with Vite
- Updated CI for Vite/Node.js
- Customizable badge colors
- Test database file exclusions

---

## Development Notes

### Conventions
- Stimulus controller filenames use hyphens: `task-modal_controller.js`
- Task types match between Ruby enums and JS
- Color definitions shared between backend and frontend
- RESTful routing throughout

### Known Issues to Watch
- Task modal controller has naming inconsistency (hyphen vs underscore)
- Deleted task_modal_controller.js may need git cleanup

### Extension Points
- Additional sowing methods (fridge_stratify is placeholder)
- More task types can be added to enum
- Calendar view is extensible with FullCalendar plugins
- Settings model ready for additional key-value pairs

---

## Quick Reference Commands

```bash
# Start development
bin/dev

# Run tests
bin/rails test
bin/rails test:system

# Database
bin/rails db:migrate
bin/rails db:seed

# Vite
bin/vite build
bin/vite dev

# Linting
bin/rubocop
```

---

**End of Overview**
