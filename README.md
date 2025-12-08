# Seedling Scheduler

A Rails web application that helps gardeners manage seed starting and transplanting schedules based on their local last frost date.

## Overview

Seedling Scheduler automatically calculates when to start seeds indoors, begin hardening off seedlings, and plant them outside based on your region's last frost date. Perfect for home gardeners who want to optimize their planting schedule without manual date tracking.

## Key Features

- **Plant Management**: Create and manage plants with different sowing methods (indoor, direct sow, winter sow, stratify-then-indoor)
- **Automatic Task Generation**: Tasks are calculated automatically based on your frost date and plant timing parameters
- **Task Dashboard**: View all upcoming gardening tasks from the past 7 days onward
- **Configurable Frost Date**: Update your regional last frost date and all tasks regenerate automatically
- **Multiple Sowing Methods**: Support for various growing strategies with smart task generation

## Quick Start

### Prerequisites

- Ruby 3.3+
- Rails 8.1+
- SQLite 3

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd seedling_scheduler

# Install dependencies
bundle install

# Setup database
bin/rails db:create
bin/rails db:migrate

# Load sample data (optional)
bin/rails db:seed

# Start the server
bin/rails server
```

Visit `http://localhost:3000` to see your task dashboard.

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
- Click **Upcoming Tasks** to see your dashboard
- Tasks show when to:
  - Start seeds indoors
  - Begin hardening off
  - Plant outside

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
- **Frontend**: Turbo, Stimulus, Importmap
- **Deployment**: Kamal-ready
- **Cache/Queue**: Solid Cache, Solid Queue

## Development

```bash
# Run tests
bin/rails test

# Run system tests
bin/rails test:system

# Run migrations
bin/rails db:migrate

# Reset database (warning: destroys data)
bin/rails db:reset
```

## Deployment

This application is configured for deployment with Kamal. See the `.kamal/` directory for deployment configuration.

## License

[Add your license here]

