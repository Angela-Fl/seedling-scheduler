# Seedling Scheduler - Comprehensive Overview

## Table of Contents

1. [Introduction](#introduction)
2. [How It Works](#how-it-works)
3. [Data Model](#data-model)
4. [Features and Workflows](#features-and-workflows)
5. [Application Structure](#application-structure)
6. [Development Guide](#development-guide)
7. [Examples and Use Cases](#examples-and-use-cases)

---

## Introduction

### The Problem

Home gardeners need to track complex timing for seed starting:
- Different plants require different lead times before the last frost
- Indoor-started plants need hardening off periods
- Direct-sown plants must wait until after frost danger passes
- Timing varies by region based on local frost dates

Manual tracking with calendars is error-prone and tedious.

### The Solution

**Seedling Scheduler** is a Rails web application that automates gardening task scheduling. You configure:
1. Your local last frost date (e.g., May 15)
2. Plants with their timing requirements (e.g., "start 10 weeks before frost")

The app automatically calculates and displays when to:
- Start seeds indoors
- Begin hardening off seedlings
- Plant outside (seedlings or direct-sown seeds)

### Target Users

- Home gardeners planning seasonal planting
- Market gardeners managing multiple plant varieties
- Garden educators teaching about growing seasons
- Anyone who wants to optimize their seed starting schedule

---

## How It Works

### The Frost Date Concept

The **last frost date** is the average date of the last killing frost in spring for your region. It's the key reference point for all timing:

- **Before frost**: Indoor seed starting, hardening off
- **After frost**: Planting tender plants outside

Example: If your frost date is May 15:
- Start tomatoes 6 weeks before = April 3
- Harden off 1 week before = May 8
- Plant outside 1 week after = May 22

### Task Generation Algorithm

When you create or update a plant, the app:

1. **Destroys existing tasks** for that plant
2. **Creates new tasks** based on sowing method:

```ruby
# From app/models/plant.rb (lines 31-60)

# START task (indoor/stratify/winter_sow methods)
if weeks_before_last_frost_to_start.present?
  due_date = last_frost_date - weeks_before_last_frost_to_start.weeks
  tasks.create!(task_type: "start", due_date: due_date, ...)
end

# HARDEN_OFF task (indoor and stratify_then_indoor only)
if weeks_before_last_frost_to_transplant.present? && sowing_method.in?(%w[indoor stratify_then_indoor])
  due_date = last_frost_date - weeks_before_last_frost_to_transplant.weeks
  tasks.create!(task_type: "harden_off", due_date: due_date, ...)
end

# PLANT task (all methods)
if weeks_after_last_frost_to_plant.present?
  due_date = last_frost_date + weeks_after_last_frost_to_plant.weeks
  tasks.create!(task_type: "plant", due_date: due_date, ...)
end
```

### Sowing Method Differences

The app supports four sowing methods, each generating different tasks:

| Sowing Method | START | HARDEN_OFF | PLANT |
|---------------|-------|------------|-------|
| **indoor** | ✓ Start indoors | ✓ Harden off | ✓ Plant seedlings |
| **direct_sow** | ✗ | ✗ | ✓ Plant seeds |
| **winter_sow** | ✓ Start winter sowing | ✗ | ✓ Plant seedlings |
| **stratify_then_indoor** | ✓ Start (after stratify) | ✓ Harden off | ✓ Plant seedlings |

**Why these differences?**
- **Direct sow**: Seeds go straight in the ground, no indoor start or hardening
- **Winter sow**: Seeds started outdoors in winter containers, already hardened by nature
- **Stratify then indoor**: Cold treatment first, then indoor start

---

## Data Model

### Plant Model

**File**: `app/models/plant.rb`

**Relationships**:
```ruby
has_many :tasks, dependent: :destroy
```

**Key Attributes**:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | Yes | Plant name (e.g., "Tomato") |
| `variety` | string | No | Variety (e.g., "Cherokee Purple") |
| `sowing_method` | enum | Yes | How the plant is started |
| `weeks_before_last_frost_to_start` | integer | Conditional* | Weeks before frost to start indoors |
| `weeks_before_last_frost_to_transplant` | integer | No | Weeks before frost to harden off |
| `weeks_after_last_frost_to_plant` | integer | Conditional** | Weeks after frost to plant out |
| `notes` | text | No | User notes |

*Required for `indoor`, `stratify_then_indoor`, and `winter_sow` methods
**Required for `direct_sow` method

**Enums**:
```ruby
enum :sowing_method, {
  indoor: "indoor",
  direct_sow: "direct_sow",
  winter_sow: "winter_sow",
  stratify_then_indoor: "stratify_then_indoor"
}
```

**Validations**:
- `name` must be present
- `sowing_method` must be present
- Numeric fields must be >= 0
- Custom validation: indoor/stratify/winter_sow methods require `weeks_before_last_frost_to_start`
- Custom validation: direct_sow requires `weeks_after_last_frost_to_plant`

**Key Method**:
```ruby
def generate_tasks!(last_frost_date)
  # Destroys all existing tasks
  # Creates new tasks based on sowing method and timing
end
```

### Task Model

**File**: `app/models/task.rb`

**Relationships**:
```ruby
belongs_to :plant, optional: true
```

**Key Attributes**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `plant_id` | integer | Foreign key to plants table (optional) |
| `task_type` | enum | Type of task (plant_seeds, begin_hardening_off, plant_seedlings) |
| `due_date` | date | When the task is due |
| `status` | enum | Current status (pending, done, skipped) |
| `notes` | text | Optional task-specific notes |

**Note**: Tasks can now exist without a plant association, allowing for general gardening tasks that aren't tied to specific plants.

**Enums**:
```ruby
enum :task_type, {
  start: "start",
  harden_off: "harden_off",
  plant: "plant"
}, prefix: :task

enum :status, {
  pending: "pending",
  done: "done",
  skipped: "skipped"
}, prefix: true
```

**Display Logic**:

The `display_name` method provides human-friendly labels:

```ruby
def display_name
  case task_type
  when "start"
    "Start indoors"
  when "harden_off"
    "Begin hardening off"
  when "plant"
    case plant.sowing_method
    when "indoor", "stratify_then_indoor"
      "Plant seedlings"
    when "direct_sow"
      "Plant seeds"
    when "winter_sow"
      "Plant out winter-sown seedlings"
    end
  end
end
```

**Status Methods**:
```ruby
task.done!     # Mark as completed
task.skip!     # Mark as skipped
task.pending?  # Check if pending
```

### Setting Model

**File**: `app/models/setting.rb`

A simple key-value store for application settings, currently used for the last frost date.

**Key Attributes**:

| Attribute | Type | Description |
|-----------|------|-------------|
| `key` | string | Unique setting identifier |
| `value` | string | Setting value (stored as string) |

**Key Methods**:

```ruby
# Get the current frost date (or default)
Setting.frost_date
# => #<Date: 2026-05-15>

# Update the frost date
Setting.set_frost_date(Date.new(2026, 5, 20))
```

**Default**: If no frost date is set, defaults to `Date.new(2026, 5, 15)`

**Implementation**:
```ruby
def self.frost_date
  val = find_by(key: "frost_date")&.value
  val.present? ? Date.parse(val) : Date.new(2026, 5, 15)
end

def self.set_frost_date(date)
  setting = find_or_initialize_by(key: "frost_date")
  setting.value = date.to_s
  setting.save!
end
```

### Database Schema

**File**: `db/schema.rb`

**plants table**:
```ruby
create_table "plants" do |t|
  t.string "name"
  t.string "variety"
  t.string "sowing_method"
  t.integer "weeks_before_last_frost_to_start"
  t.integer "weeks_before_last_frost_to_transplant"
  t.integer "weeks_after_last_frost_to_plant"
  t.text "notes"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
end
```

**tasks table**:
```ruby
create_table "tasks" do |t|
  t.integer "plant_id", null: false
  t.string "task_type"
  t.date "due_date"
  t.string "status"
  t.text "notes"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["plant_id"], name: "index_tasks_on_plant_id"
end

add_foreign_key "tasks", "plants"
```

**settings table**:
```ruby
create_table "settings" do |t|
  t.string "key"
  t.string "value"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
end
```

---

## Features and Workflows

### Feature 1: Creating Plants

**User Journey**:
1. Navigate to Plants → New Plant
2. Fill out the form:
   - Name and variety
   - Select sowing method
   - Enter timing parameters (conditional fields appear)
   - Add optional notes
3. Click "Create Plant"

**What Happens**:
```ruby
# app/controllers/plants_controller.rb (create action)
@plant = Plant.new(plant_params)
if @plant.save
  @plant.generate_tasks!(Setting.frost_date)  # Auto-generate tasks
  redirect_to @plant
end
```

**Result**: Plant is saved and tasks are automatically created based on current frost date.

### Feature 2: Viewing Task Dashboard

**URL**: `/` (root path)

**What's Shown**:
- Current last frost date
- All tasks from 7 days ago to future dates
- Ordered by due date (soonest first)
- Task information:
  - Due date
  - Task type (with smart labels)
  - Plant name and variety
  - Notes

**Implementation**:
```ruby
# app/controllers/tasks_controller.rb
@tasks = Task.includes(:plant)
             .where("due_date >= ?", 7.days.ago.to_date)
             .order(:due_date)
```

**Why 7 days ago?** Allows viewing recently passed tasks you might have missed.

### Feature 3: Configuring Frost Date

**URL**: `/settings/edit`

**User Journey**:
1. Click Settings in navbar
2. Select new frost date using date picker
3. Click "Save and regenerate tasks"

**What Happens**:
```ruby
# app/controllers/settings_controller.rb (update action)
new_date = Date.parse(params[:frost_date])
Setting.set_frost_date(new_date)

# Regenerate ALL tasks for ALL plants
Plant.find_each do |plant|
  plant.generate_tasks!(Setting.frost_date)
end
```

**Result**: Frost date updated, all task dates recalculated automatically.

**Error Handling**: Invalid dates show an error message without changing the setting.

### Feature 4: Managing Plants

**Editing Plants**:
- Click plant name → Edit
- Modify any fields
- On save, tasks regenerate automatically

**Deleting Plants**:
- Click "Destroy" on plant page
- Plant and all associated tasks are deleted (cascade delete)

**Regenerating Tasks Manually**:
- Click "Regenerate tasks" on plant page
- Forces task recalculation without changing plant data
- Useful if you've manually modified tasks

### Feature 5: Hardening Off Logic

The app recognizes that not all plants need hardening off:

**Direct sow plants**: No hardening task generated
- Seeds go straight in the ground
- Example: Carrots, beans, sunflowers

**Winter sown plants**: No hardening task generated
- Already outdoors, naturally hardened
- Example: Echinacea, rudbeckia

**Indoor/stratified plants**: Hardening task created
- Seedlings need gradual outdoor exposure
- Example: Tomatoes, peppers, brassicas

**Implementation**:
```ruby
# Only create harden_off task for indoor and stratify_then_indoor
if weeks_before_last_frost_to_transplant.present() &&
   sowing_method.in?(%w[indoor stratify_then_indoor])
  tasks.create!(task_type: "harden_off", ...)
end
```

### Feature 6: Calendar View

**URL**: `/tasks/calendar`

**Description**: Interactive calendar interface powered by FullCalendar that visualizes all gardening tasks.

**Features**:
- **Visual Task Display**: All tasks appear as events on a calendar grid
- **Drag-and-Drop Rescheduling**: Click and drag tasks to new dates
- **Task Creation**: Click on any date to create a new task
- **Task Editing**: Click existing tasks to view and edit details
- **Multiple Calendar Views**: Month, week, and day views available
- **Color-Coded Events**: Tasks color-coded by status (pending, done, skipped)
- **Date Range Filtering**: Calendar automatically fetches tasks for the visible date range

**Technology**:
- FullCalendar library with Bootstrap 5 theme
- Stimulus controller (`calendar_controller.js`) for initialization and event handling
- JSON API endpoints for data loading and updates

**User Journey**:
1. Navigate to Tasks → Task Calendar
2. View tasks laid out across calendar dates
3. Interact with tasks:
   - Drag to reschedule
   - Click to edit
   - Create new tasks on specific dates
4. Switch between calendar and table views using view toggles

### Feature 7: JSON API

**Description**: RESTful JSON API for programmatic access to tasks.

**Endpoints**:

#### GET /tasks.json
Retrieve all tasks as JSON.

**Query Parameters**:
- `start` (ISO 8601 date): Filter tasks starting from this date
- `end` (ISO 8601 date): Filter tasks ending at this date

**Response**:
```json
[
  {
    "id": 1,
    "due_date": "2026-05-15",
    "task_type": "plant_seeds",
    "status": "pending",
    "notes": "Start indoors",
    "plant_id": 1,
    "plant_name": "Tomato",
    "plant_variety": "Cherokee Purple"
  }
]
```

#### POST /tasks.json
Create a new task.

**Request Body**:
```json
{
  "task": {
    "plant_id": 1,          // Optional
    "task_type": "plant_seeds",
    "due_date": "2026-05-15",
    "status": "pending",
    "notes": "Optional notes"
  }
}
```

**Response**: 201 Created with task JSON

#### PATCH /tasks/:id.json
Update an existing task.

**Request Body**:
```json
{
  "task": {
    "status": "done",
    "notes": "Updated notes"
  }
}
```

**Response**: 200 OK with updated task JSON

**Use Cases**:
- Calendar integration (FullCalendar fetches tasks via JSON)
- Mobile app development
- Task automation scripts
- Third-party integrations
- Export/backup tools

### Feature 8: General Tasks

**Description**: Tasks can now be created without associating them to a specific plant.

**Use Cases**:
- General garden maintenance (e.g., "Clean greenhouse")
- Seasonal activities (e.g., "Order seeds")
- Infrastructure tasks (e.g., "Repair irrigation")
- Reminders not plant-specific (e.g., "Fertilize all beds")

**Implementation**:
```ruby
# Task model allows optional plant association
belongs_to :plant, optional: true

# Display logic handles nil plants
def display_subject
  if plant
    "#{plant.name} - #{display_name}"
  else
    display_name  # Just task type for general tasks
  end
end
```

**Creating General Tasks**:
- Use the calendar view to create tasks on specific dates
- Use the JSON API with `plant_id` omitted
- Tasks without plants display task type only

---

## Application Structure

### Controllers

**File**: `app/controllers/`

#### TasksController (`tasks_controller.rb`)
- **index**: Shows task dashboard or returns JSON
  - Eager loads plants to avoid N+1 queries
  - Filters to past 7 days onward
  - Orders by due date
  - Responds to HTML and JSON formats
  - JSON format supports date range filtering
- **calendar**: Renders calendar view
- **create**: Creates new tasks via JSON API
- **update**: Updates tasks via JSON API

#### PlantsController (`plants_controller.rb`)
- **index**: Lists all plants alphabetically
- **show**: Displays plant details and its tasks
- **new/edit**: Form views for plant management
- **create**: Creates plant, generates tasks
- **update**: Updates plant, regenerates tasks
- **destroy**: Deletes plant (cascades to tasks)
- **regenerate_tasks**: Custom action to regenerate tasks manually

#### SettingsController (`settings_controller.rb`)
- **edit**: Shows frost date configuration form
- **update**: Updates frost date, regenerates all tasks
- Error handling for invalid date formats

#### ApplicationController (`application_controller.rb`)
- Base controller with Rails 8 defaults
- Modern browser requirement
- Importmap configuration

### Routes

**File**: `config/routes.rb`

```ruby
Rails.application.routes.draw do
  root "tasks#index"  # Dashboard

  resource :settings, only: [:edit, :update]  # Singular resource

  resources :plants do
    member do
      post :regenerate_tasks  # Custom member action
    end
  end

  resources :tasks, only: [:index, :create, :update] do
    collection do
      get :calendar  # Calendar view
    end
  end
end
```

**Key Routes**:
- `GET /` → tasks#index (dashboard)
- `GET /tasks` → tasks#index (supports JSON)
- `GET /tasks/calendar` → tasks#calendar (calendar view)
- `POST /tasks` → tasks#create (JSON API)
- `PATCH /tasks/:id` → tasks#update (JSON API)
- `GET /plants` → plants#index
- `GET /plants/:id` → plants#show
- `GET /plants/new` → plants#new
- `POST /plants` → plants#create
- `GET /plants/:id/edit` → plants#edit
- `PATCH /plants/:id` → plants#update
- `DELETE /plants/:id` → plants#destroy
- `POST /plants/:id/regenerate_tasks` → plants#regenerate_tasks
- `GET /settings/edit` → settings#edit
- `PATCH /settings` → settings#update

### View Templates

**File**: `app/views/`

#### layouts/application.html.erb
- Main layout with navbar
- Navigation: Upcoming Tasks | Plants | Settings
- Turbo and Stimulus integration
- PWA-ready (manifest commented out)

#### tasks/index.html.erb
- Task dashboard (table view)
- Displays frost date
- Table of tasks with plant information
- Conditionally shows task type labels
- View switcher to toggle to calendar view

#### tasks/calendar.html.erb
- Calendar view of tasks
- FullCalendar integration
- Interactive task management
- Date picker for frost date
- View switcher to toggle to table view

#### tasks/_task_modal.html.erb
- Modal dialog for creating/editing tasks
- Used by calendar view
- Bootstrap modal component

#### plants/
- `index.html.erb` - Plant list
- `show.html.erb` - Plant details with tasks
- `new.html.erb` - Create plant form
- `edit.html.erb` - Edit plant form
- `_form.html.erb` - Shared form partial

#### settings/edit.html.erb
- Frost date configuration form
- Date picker input
- Explanation of what happens on save

### Database

**Type**: SQLite 3

**Configuration**: `config/database.yml`
- Development: `storage/development.sqlite3`
- Test: `storage/test.sqlite3`
- Production: `storage/production.sqlite3`

**Migrations**: `db/migrate/`
- Three migrations:
  1. Create plants
  2. Create tasks
  3. Create settings

**Schema**: `db/schema.rb` (version-controlled, auto-generated)

**Seeds**: `db/seeds.rb`
- Clears existing data (safe for dev)
- Creates three sample plants (Zinnia, Snapdragon, Sunflower)
- Generates tasks for each

---

## Development Guide

### Tech Stack

**Backend**:
- Ruby 3.3+
- Rails 8.1
- SQLite 3

**Frontend**:
- Vite (modern build tool and dev server)
- Turbo (SPA-like experience)
- Stimulus (JavaScript framework)
- Bootstrap 5.3 (UI framework)
- FullCalendar (interactive calendar widget)

**Infrastructure**:
- Puma (web server)
- Solid Cache (database-backed cache)
- Solid Queue (database-backed jobs)
- Solid Cable (database-backed WebSockets)

**Deployment**:
- Kamal (Docker deployment)
- Thruster (HTTP caching/compression)

**Development Tools**:
- Debug (debugging)
- Web Console (in-browser console)
- Bundler Audit (security)
- Brakeman (vulnerability scanning)
- RuboCop (Rails Omakase style guide)

**Testing**:
- Minitest (test framework)
- Capybara (integration testing)
- Selenium (browser automation)

### Running Tests

```bash
# Run all tests
bin/rails test

# Run system tests
bin/rails test:system

# Run specific test file
bin/rails test test/models/plant_test.rb

# Run with verbose output
bin/rails test -v
```

### Database Management

```bash
# Create database
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Reset database (WARNING: destroys all data)
bin/rails db:reset

# Seed database
bin/rails db:seed

# Open database console
bin/rails dbconsole
```

### Code Quality

```bash
# Run RuboCop
bundle exec rubocop

# Auto-fix RuboCop issues
bundle exec rubocop -a

# Security audit
bundle exec bundler-audit

# Brakeman security scan
bundle exec brakeman
```

### Deployment with Kamal

This app is configured for Docker deployment with Kamal:

```bash
# Setup Kamal (first time)
kamal setup

# Deploy
kamal deploy

# View logs
kamal app logs

# Access console on production
kamal app exec -i --reuse bin/rails console
```

Configuration: `.kamal/` directory

### Development Server

```bash
# Start server (default: http://localhost:3000)
bin/rails server

# Start on different port
bin/rails server -p 3001

# Start in production mode (not recommended for dev)
RAILS_ENV=production bin/rails server
```

---

## Examples and Use Cases

### Example 1: Spring Garden Planning

**Scenario**: Plan a spring vegetable garden for Zone 7a (last frost: April 15)

**Setup**:
1. Set frost date: April 15, 2026
2. Add plants:

| Plant | Variety | Method | Start Before | Harden Before | Plant After |
|-------|---------|--------|--------------|---------------|-------------|
| Tomato | Cherokee Purple | indoor | 6 weeks | 1 week | 2 weeks |
| Lettuce | Buttercrunch | direct_sow | - | - | 2 weeks |
| Pepper | Bell | indoor | 8 weeks | 1 week | 2 weeks |
| Basil | Genovese | indoor | 6 weeks | 1 week | 2 weeks |

**Generated Tasks**:
- March 4: Start peppers indoors
- March 18: Start tomatoes and basil indoors
- April 8: Harden off peppers
- April 22: Harden off tomatoes and basil
- April 29: Plant lettuce seeds, plant out peppers, tomatoes, basil

### Example 2: Frost Date Change

**Scenario**: You realize your frost date is actually May 1, not April 15

**Action**:
1. Go to Settings
2. Change frost date to May 1, 2026
3. Click "Save and regenerate tasks"

**Result**: All task dates shift automatically:
- Peppers start: March 20 (was March 4)
- Tomatoes start: April 3 (was March 18)
- Hardening dates shift forward
- Planting dates shift forward

All timing relationships preserved, no manual recalculation needed.

### Example 3: Multi-Season Planning

**Plants You Might Track**:

**Early Spring** (direct sow before frost):
- Peas (4 weeks before frost)
- Spinach (6 weeks before frost)
- Radishes (4 weeks before frost)

**Spring** (after frost):
- Tomatoes, peppers (indoor start)
- Beans, squash (direct sow)

**Fall** (reverse planning):
*Note: Current version uses last spring frost. Fall frost requires additional feature.*

### Example 4: Specialized Growing Methods

**Winter Sowing** (outdoor cold stratification):
```
Method: winter_sow
Start: 10 weeks before frost (set up winter sowing containers)
Harden: N/A (already outdoors)
Plant: 1 week after frost
```
Tasks: Start reminder and planting date (no hardening needed)

**Cold Stratification Then Indoor**:
```
Method: stratify_then_indoor
Start: 10 weeks before (after 4-6 week stratify)
Harden: 2 weeks before
Plant: 1 week after
```
Tasks: All three tasks, with start date accounting for stratification period

### Example 5: Task Calculation

**Given**:
- Frost date: May 15, 2026
- Plant: Snapdragon
- Start: 10 weeks before frost
- Harden: 1 week before frost
- Plant: 1 week after frost

**Calculations**:
```
Start date:  May 15 - 10 weeks = March 6, 2026
Harden date: May 15 - 1 week   = May 8, 2026
Plant date:  May 15 + 1 week   = May 22, 2026
```

**Timeline**:
1. March 6: Start snapdragon seeds indoors
2. May 8: Begin hardening off (set outside during day)
3. May 22: Plant in garden

---

## Future Enhancement Ideas

*This section describes potential improvements not yet implemented*

### Multi-User Support
- User authentication
- Per-user frost dates
- Shared plant libraries

### Fall Planting
- Support for fall frost dates
- Reverse calculations (count back from first frost)
- Succession planting schedules

### Task Management
- Mark tasks as done/skipped from dashboard
- Task filtering (by status, plant, date range)
- Task notes and photos

### Plant Database
- Pre-populated plant library with common timing
- Import/export plant configurations
- Community-shared plant data

### Notifications
- Email reminders for upcoming tasks
- SMS notifications
- Calendar integration (iCal export)

### Advanced Features
- Succession planting (multiple plantings, staggered dates)
- Companion planting suggestions
- Growing zone auto-detection by ZIP code
- Mobile app (PWA enhancement)

---

## Conclusion

Seedling Scheduler is a focused, practical tool for home gardeners. Its core strength is automatic task calculation based on configurable frost dates, eliminating manual date tracking and calendar management.

The app demonstrates clean Rails architecture with:
- Clear model responsibilities
- RESTful routing
- Efficient database queries
- Modern frontend with Turbo/Stimulus

For questions or contributions, see the project repository.
