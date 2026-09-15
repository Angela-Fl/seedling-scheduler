# Seedling Scheduler

A Rails web application that helps gardeners manage seed starting and transplanting schedules based on their local last frost date.

## Overview

Seedling Scheduler automatically calculates when to start seeds indoors, begin hardening off seedlings, and plant them outside based on your region's last frost date. Perfect for home gardeners who want to optimize their planting schedule without manual date tracking.

## Key Features

- **Plant Management**: Create and manage plants with different sowing methods (indoor, direct sow, winter sow, stratify-then-indoor)
- **Automatic Task Generation**: Tasks are calculated automatically based on your frost date and plant timing parameters
- **Task Dashboard**: View all upcoming gardening tasks from the past 7 days onward in table or calendar format
- **Interactive Calendar**: Visual calendar view powered by FullCalendar with drag-and-drop task management
- **Configurable Frost Date**: Update your regional last frost date and all tasks regenerate automatically
- **Multiple Sowing Methods**: Support for various growing strategies with smart task generation
- **General Tasks**: Create tasks not tied to specific plants for general gardening activities
- **JSON API**: Programmatic access to tasks for integration with other tools
- **Garden Journal**: Create dated entries to track observations, actions, and plans

## Quick Start

### Prerequisites

- Ruby 3.3+
- Rails 8.1+
- SQLite 3
- Node.js 24 (pinned in `.node-version`, and what CI builds against)
- npm (comes with Node.js)

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd seedling_scheduler

# Install Ruby dependencies
bundle install

# Install Node.js dependencies
npm install

# Setup database
bin/rails db:create
bin/rails db:migrate

# Load sample data (optional)
bin/rails db:seed

# Build frontend assets
bin/vite build

# Start the development server
bin/dev
```

The `bin/dev` command starts both the Rails server and the Vite development server using Foreman, reading the process list from `Procfile.dev`. Visit `http://localhost:3000` to see your task dashboard; the Vite dev server runs alongside it on port 3036 and gives you hot module replacement, so edits to `app/frontend/` patch the running page instead of forcing a full rebuild.

Two things to expect on first run:

- If Foreman is not installed, `bin/dev` installs it for you. It is deliberately kept out of the `Gemfile` — running Foreman inside Bundler leaks the parent bundle context into the processes it spawns.
- The initial Vite start is slow (up to a couple of minutes) while it pre-bundles dependencies. Later starts are fast, because the result is cached in `node_modules/.vite`. Until Vite is listening, Rails falls back to building assets on demand, so the first page load during that window can be slow.

Alternatively, you can run them separately:
```bash
# Terminal 1: Rails server
bin/rails server

# Terminal 2: Vite dev server
bin/vite dev
```

Running `bin/rails server` on its own also works, without hot module replacement: `config/vite.json` sets `autoBuild` for development, so Rails rebuilds the bundle on demand and serves it from `public/vite-dev`.

## Basic Usage

### 1. Set Your Frost Date
- Navigate to **Settings** in the navbar
- Enter your local last frost date (default: May 15, 2026)
- Click "Save and regenerate tasks"

### 2. Add Plants
- Click **Plants** → **New Plant**
- Enter plant details:
  - Name and variety
  - Sowing method (how you'll grow it)
  - Timing parameters (weeks before/after frost)
- Tasks are generated automatically when you save

### 3. View Your Schedule
- Click **Task Table** to see tasks in a sortable table format
- Click **Task Calendar** for an interactive calendar view
- Toggle between table and calendar views with the view switcher
- Tasks show when to:
  - Start seeds indoors
  - Begin hardening off
  - Plant outside
- In calendar view:
  - Drag and drop tasks to reschedule
  - Click tasks to edit details
  - Create new tasks by clicking on dates

### 4. Manage Plants
- Edit plants to update timing or details
- Tasks regenerate automatically when you save changes
- Delete plants you no longer need

## Sample Data

The seed file includes three example plants:

- **Zinnia** (indoor start, 6 weeks before frost)
- **Snapdragon** (indoor start, 10 weeks before frost)
- **Sunflower** (direct sow, 1 week after frost)

## Documentation

For detailed documentation, see:

- **[docs/OVERVIEW.md](docs/OVERVIEW.md)** - Comprehensive project guide
- **[docs/BOOTSTRAP.md](docs/BOOTSTRAP.md)** - Bootstrap integration and customization guide

## Tech Stack

- **Framework**: Rails 8.1
- **Database**: SQLite 3
- **Frontend**:
  - Vite (modern build tool)
  - Turbo (SPA-like page updates)
  - Stimulus (JavaScript framework)
  - Bootstrap 5.3 (UI components)
  - FullCalendar (interactive calendar)
- **Deployment**: Kamal-ready
- **Cache/Queue**: Solid Cache, Solid Queue

## Development

```bash
# Run tests
bin/rails test

# Run system tests
bin/rails test:system

# Build frontend assets for test environment
RAILS_ENV=test bin/vite build

# Run migrations
bin/rails db:migrate

# Reset database (warning: destroys data)
bin/rails db:reset

# Rebuild Vite assets
bin/vite build

# Watch frontend files and rebuild on change
bin/vite dev
```

## Deployment

This application is configured for deployment with Kamal. See the `.kamal/` directory for deployment configuration.

## License

[Add your license here]

