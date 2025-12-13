# Seedling Scheduler - Development Changelog

## December 13, 2024

### Major Feature: Calendar View and JSON API

#### Frontend Build System Migration
**Migration from Importmap to Vite**
- Installed Node.js and npm dependencies
- Added Vite Ruby gem for Rails integration
- Configured Vite with custom settings:
  - Source directory: `app/frontend`
  - Separate build outputs for dev and test environments
  - Auto-build enabled for test environment
- Created `vite.config.ts` with TypeScript support
- Set up `Procfile.dev` for concurrent Rails and Vite servers
- Added `.node-version` file for Node.js version management

**New Dependencies**:
- **Build Tools**: Vite, vite-plugin-ruby
- **JavaScript Libraries**: @hotwired/turbo-rails, @hotwired/stimulus
- **UI Framework**: Bootstrap 5.3.3, @popperjs/core
- **Calendar**: FullCalendar (core, daygrid, interaction, multimonth, bootstrap5)
- **Action Cable**: @rails/actioncable

**Frontend Structure**:
- `app/frontend/` - New frontend source directory
  - `entrypoints/application.js` - Main entry point
  - `controllers/` - Stimulus controllers
  - `stylesheets/` - CSS files
  - `lib/` - Shared JavaScript modules
- `app/javascript/entrypoints/application.js` - Legacy entry point (kept for compatibility)

#### Calendar View Implementation

**New Route**: `/tasks/calendar`

**Features**:
- Interactive monthly calendar powered by FullCalendar
- Visual display of all gardening tasks
- Drag-and-drop task rescheduling
- Click to create new tasks on specific dates
- Click existing tasks to edit details
- Color-coded by task status (pending, done, skipped)
- Multiple view options (month, week, day)
- Seamless integration with Bootstrap 5 theme

**New Files**:
- `app/views/tasks/calendar.html.erb` - Calendar view template
- `app/views/tasks/_task_modal.html.erb` - Task creation/edit modal
- `app/frontend/controllers/calendar_controller.js` - Stimulus controller for calendar initialization and event handling
- `app/frontend/lib/calendar-utils.js` - Shared calendar utility functions

**Controller Updates**:
- `TasksController#calendar` - New action to render calendar view
- `TasksController#index` - Enhanced to support JSON format with date range filtering
- `TasksController#create` - New action for creating tasks via JSON API
- `TasksController#update` - New action for updating tasks via JSON API

#### JSON API Implementation

**New API Endpoints**:
1. **GET /tasks.json**
   - Returns all tasks as JSON
   - Supports date range filtering via `start` and `end` parameters
   - Includes plant information (name, variety)
   - Used by calendar for dynamic data loading

2. **POST /tasks.json**
   - Creates new tasks programmatically
   - Supports both plant-associated and general tasks
   - Returns created task with 201 status

3. **PATCH /tasks/:id.json**
   - Updates existing tasks
   - Supports partial updates
   - Returns updated task with 200 status
   - Validates changes and returns 422 for invalid data

**API Response Format**:
```json
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
```

**Use Cases**:
- Calendar event data source
- Third-party integrations
- Mobile app development
- Task automation scripts
- Backup/export tools

#### Optional Plant Association for Tasks

**Database Migration**: `20251213024759_make_plant_id_optional_in_tasks.rb`
- Made `plant_id` optional in tasks table
- Updated foreign key constraint to allow null values
- Enables creation of general gardening tasks

**Model Changes**:
- Updated `Task` model: `belongs_to :plant, optional: true`
- Enhanced `display_subject` method to handle tasks without plants
- Tasks without plants display task type only

**New Functionality**:
- Create tasks for general garden maintenance
- Seasonal reminders not tied to specific plants
- Infrastructure and planning tasks
- Examples:
  - "Clean greenhouse"
  - "Order new seeds"
  - "Repair irrigation system"
  - "Fertilize all beds"

#### View Enhancements

**Navigation Updates**:
- Added "Task Calendar" link to navbar
- Task views now include view switcher buttons
- Toggle between table and calendar views
- Active view highlighted in UI

**Task Modal**:
- Bootstrap modal for task creation/editing
- Form includes:
  - Plant selection (optional)
  - Task type dropdown
  - Due date picker
  - Status selection
  - Notes textarea
- Client-side validation
- AJAX form submission

#### Test Coverage

**New Test Files and Updates**:
- Added 3 new tests to `test/models/task_test.rb`:
  - `test_task_can_be_created_without_a_plant`
  - `test_display_subject_shows_only_task_name_when_plant_is_nil`
  - `test_display_subject_includes_plant_name_when_plant_is_present`

- Added 9 new tests to `test/controllers/tasks_controller_test.rb`:
  - `test_should_get_calendar_view`
  - `test_calendar_view_shows_last_frost_date`
  - `test_index_returns_JSON_with_tasks`
  - `test_index_JSON_filters_by_date_range`
  - `test_create_task_via_JSON_API`
  - `test_create_task_without_plant_via_JSON_API`
  - `test_update_task_via_JSON_API`
  - `test_update_task_with_invalid_data_returns_error`

**Test Environment Setup**:
- Added Vite build step for test environment
- Updated `test_helper.rb` to handle Vite assets
- All 108 tests passing (up from 97)

#### Configuration Updates

**Vite Configuration** (`config/vite.json`):
```json
{
  "all": {
    "sourceCodeDir": "app/frontend",
    "watchAdditionalPaths": []
  },
  "development": {
    "autoBuild": true,
    "publicOutputDir": "vite-dev",
    "port": 3036
  },
  "test": {
    "autoBuild": true,
    "publicOutputDir": "vite-test",
    "port": 3037
  }
}
```

**Package.json**:
- Added build and dev scripts
- Configured dependencies for calendar and UI components
- Added TypeScript types for better development experience

**Gemfile Updates**:
- Added `vite_rails` gem
- Updated development dependencies

#### Documentation Updates

**Updated Files**:
- `README.md` - Added Node.js prerequisites, Vite setup instructions, calendar feature
- `docs/OVERVIEW.md` - Added sections for calendar view, JSON API, and general tasks
- `docs/CHANGELOG.md` - This comprehensive changelog entry

**New Documentation Sections**:
- Frontend build system requirements
- Calendar view usage guide
- JSON API endpoint documentation
- General tasks feature explanation

#### Summary of Changes

**Files Added**:
- `vite.config.ts` - Vite configuration
- `Procfile.dev` - Development process management
- `.node-version` - Node.js version specification
- `package.json` & `package-lock.json` - Node.js dependencies
- `app/frontend/` - New frontend directory structure
- `app/views/tasks/calendar.html.erb` - Calendar view
- `app/views/tasks/_task_modal.html.erb` - Task modal
- `app/frontend/controllers/calendar_controller.js` - Calendar Stimulus controller
- `app/frontend/lib/calendar-utils.js` - Calendar utilities
- `db/migrate/20251213024759_make_plant_id_optional_in_tasks.rb` - Migration for optional plant_id

**Files Modified**:
- `Gemfile` & `Gemfile.lock` - Added vite_rails gem
- `app/models/task.rb` - Made plant association optional, added display_subject method
- `app/controllers/tasks_controller.rb` - Added calendar, create, update actions; JSON support
- `app/views/layouts/application.html.erb` - Added calendar navigation link
- `app/views/tasks/index.html.erb` - Added view switcher
- `config/routes.rb` - Added calendar route and task API routes
- `test/models/task_test.rb` - Updated tests for optional plant_id
- `test/controllers/tasks_controller_test.rb` - Added comprehensive API and calendar tests
- `README.md` - Updated with Node.js setup and calendar features
- `docs/OVERVIEW.md` - Added calendar, API, and general tasks documentation
- `docs/CHANGELOG.md` - This entry

**Breaking Changes**: None
- All changes are backward compatible
- Existing plants and tasks work without modification
- Tests updated to reflect new optional behavior

**Migration Required**: Yes
- Run `bin/rails db:migrate` to make plant_id optional in tasks
- Run `npm install` to install Node.js dependencies
- Run `bin/vite build` to build frontend assets

**Key Benefits**:
1. **Modern Frontend Tooling**: Vite provides fast builds and hot module replacement
2. **Visual Task Management**: Calendar view makes planning more intuitive
3. **API Integration**: JSON endpoints enable third-party integrations
4. **Flexible Task System**: General tasks support broader use cases
5. **Better UX**: Interactive calendar with drag-and-drop functionality

## December 8, 2024

### Major Refactoring: Timing Model Changes

#### Database Schema Changes

**Migration: Convert to Offset Days System**
- Replaced week-based timing fields with day-based offset fields
- **Old fields (removed):**
  - `weeks_before_last_frost_to_start`
  - `weeks_before_last_frost_to_transplant`
  - `weeks_after_last_frost_to_plant`
- **New fields (added):**
  - `plant_seeds_offset_days` (integer, can be negative)
  - `hardening_offset_days` (integer, can be negative)
  - `plant_seedlings_offset_days` (integer, can be negative)
- **Sign convention:** Negative values = before last frost date, Positive values = after last frost date
- Data migration: Automatically converted existing week-based data to day-based offsets

**Migration: Enum Value Updates**
- Updated `sowing_method` enum in plants table:
  - `indoor` → `indoor_start`
  - `winter_sow` → `outdoor_start`
  - `stratify_then_indoor` → `fridge_stratify`
- Updated `task_type` enum in tasks table:
  - `start` → `plant_seeds`
  - `harden_off` → `begin_hardening_off`
  - `plant` → `plant_seedlings`
- Added `begin_stratification` task type (placeholder for future use)

#### Model Changes

**Plant Model (app/models/plant.rb)**
- Updated sowing method enum values to match new naming convention
- Changed validations to work with new offset day fields
- Simplified validation logic:
  - All plants must have `plant_seeds_offset_days` defined
  - Plants using `indoor_start` or `outdoor_start` must have `plant_seedlings_offset_days`
  - Direct sow plants don't need transplanting fields
- Rewrote `generate_tasks!` method:
  - Now uses universal `plant_seeds` task for all sowing methods
  - Generates `begin_hardening_off` task only for indoor_start plants
  - Generates `plant_seedlings` task for methods requiring transplanting
  - Adds descriptive notes to each task
  - Uses symbols instead of strings for task types and statuses

**Task Model (app/models/task.rb)**
- Updated task_type enum with new values
- Simplified `display_name` method to use straightforward task type names
- Removed complex conditional logic that depended on plant sowing method

#### View Updates

**Plant Form (app/views/plants/_form.html.erb)**
- Completely redesigned form layout using Bootstrap components
- Replaced week-based inputs with day-based offset inputs
- Added intuitive labeling:
  - "Plant seeds" field with helpful description
  - "Begin hardening off seedlings" (conditional on indoor_start)
  - "Transplant seedlings outdoors" (conditional on applicable methods)
- Implemented dynamic field visibility using JavaScript:
  - Hardening field only shows for indoor_start method
  - Transplant field hides for direct_sow method
- Added "days relative to last frost" helper text
- Improved form styling with Bootstrap card layout

**Plant Index (app/views/plants/index.html.erb)**
- Updated to use Bootstrap table styling
- Removed week-based column displays
- Streamlined table to show key information only

**Plant Show (app/views/plants/show.html.erb)**
- Redesigned layout using Bootstrap cards
- Added offset day displays with appropriate formatting
- Improved task list presentation
- Added conditional rendering for timing fields

**Tasks Index (app/views/tasks/index.html.erb)**
- Updated to use new task type display names
- Improved table layout and styling

**Application Layout (app/views/layouts/application.html.erb)**
- Updated Bootstrap navbar styling

#### Helper Updates

**Plants Helper (app/helpers/plants_helper.rb)**
- Added `format_offset_days` method to display offset days in human-readable format
- Returns "N days before last frost" or "N days after last frost" or "On last frost date"

**Tasks Helper (app/helpers/tasks_helper.rb)**
- Added `task_status_badge` method to generate Bootstrap badge HTML for task statuses
- Color-coded badges: success (completed), warning (in_progress), secondary (pending)

#### Controller Updates

**Plants Controller (app/controllers/plants_controller.rb)**
- Updated strong parameters to permit new offset day fields
- Removed old week-based field permissions
- Enhanced parameter handling for the new schema

#### Test Updates

**Fixtures**
- Updated `test/fixtures/plants.yml` with new offset day fields
- Updated `test/fixtures/tasks.yml` with new task type values

**Model Tests**
- Rewrote `test/models/plant_test.rb` to test new validations and offset day logic
- Updated `test/models/task_test.rb` to work with new task type enum values
- All tests passing with new schema

### Styling Updates

**Application CSS (app/assets/stylesheets/application.css)**
- Added extensive custom theme variables for Bootstrap
- Defined color palette: Primary (sage green), secondary (terracotta), success, info, warning, danger
- Added custom styling for:
  - Cards and forms
  - Buttons and badges
  - Tables
  - Navigation
  - Typography
  - Form inputs and validation states
- Enhanced visual design with plant/garden theme colors

## December 7, 2024

### Bootstrap Integration

**Initial Setup**
- Integrated Bootstrap 5.3.3 via importmap
- Added Popper.js for Bootstrap dropdown functionality
- Updated application layout with Bootstrap navbar
- Created comprehensive documentation in `docs/BOOTSTRAP.md`

**Custom Theme Development**
- Developed custom color scheme with garden/plant theme
- Sage green primary color (#8BA888)
- Terracotta secondary color (#C67B5C)
- Warm, earthy color palette throughout

**Documentation**
- Created `docs/BOOTSTRAP.md` with integration instructions
- Documented theme customization approach
- Added component usage examples

### Bug Fixes and Code Quality

**Rubocop Compliance**
- Fixed all Rubocop linting issues
- Improved code style consistency
- Ensured Rails best practices

**Winter Sowing Fixes**
- Fixed winter sow task generation logic
- Corrected route helper names throughout the application
- Ensured proper task creation for outdoor_start sowing method

## Earlier Development

### Initial Application Setup
- Created Rails 8.1 application
- Set up basic Plant and Task models
- Implemented initial garden planning functionality
- Created basic CRUD operations for plants and tasks
- Set up Kamal deployment configuration
- Added `.kamal/secrets` to .gitignore for security

## Summary of Major Changes

### Architecture Improvements
1. **More Flexible Timing System:** Changed from weeks to days for finer control
2. **Clearer Nomenclature:** Updated enum values to be more descriptive and intuitive
3. **Simplified Logic:** Reduced conditional complexity in models and views
4. **Better UX:** Dynamic form fields that adapt to sowing method selection

### Data Model Evolution
- Week-based offsets → Day-based offsets
- Unsigned integers with separate fields → Single signed integer per timing point
- Confusing enum names → Clear, descriptive enum values

### Frontend Enhancements
- Plain HTML forms → Bootstrap-styled, responsive forms
- Static forms → Dynamic forms with JavaScript interactivity
- Basic tables → Styled, professional-looking tables with proper formatting
- No theme → Custom garden-themed color palette

### Code Quality
- Passed Rubocop linting
- Comprehensive test coverage
- Better separation of concerns
- Helper methods for view logic

## Files Modified

### Models
- `app/models/plant.rb`
- `app/models/task.rb`

### Controllers
- `app/controllers/plants_controller.rb`

### Views
- `app/views/layouts/application.html.erb`
- `app/views/plants/_form.html.erb`
- `app/views/plants/index.html.erb`
- `app/views/plants/show.html.erb`
- `app/views/tasks/index.html.erb`

### Helpers
- `app/helpers/plants_helper.rb`
- `app/helpers/tasks_helper.rb`

### Assets
- `app/assets/stylesheets/application.css`

### Database
- `db/migrate/20251208185744_convert_to_offset_days_in_plants.rb`
- `db/migrate/20251208190226_update_sowing_method_and_task_type_enums.rb`
- `db/schema.rb`

### Tests
- `test/models/plant_test.rb`
- `test/models/task_test.rb`
- `test/fixtures/plants.yml`
- `test/fixtures/tasks.yml`

### Documentation
- `docs/BOOTSTRAP.md`
- `docs/OVERVIEW.md`

## Next Steps / Future Enhancements

### Potential Features
1. Implement fridge stratification workflow (models exist, UI pending)
2. Add calendar view for task visualization
3. Implement task notifications/reminders
4. Add mobile-responsive enhancements
5. Create seed inventory management
6. Add growing zone/region support
7. Implement succession planting calculations
8. Add companion planting recommendations

### Technical Improvements
1. Add JavaScript form validation
2. Implement AJAX task updates
3. Add date picker for last frost date selection
4. Create batch operations for plants
5. Add export/import functionality for plant data
6. Implement search and filtering for plants and tasks
