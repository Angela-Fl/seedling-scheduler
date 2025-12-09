# Seedling Scheduler - Development Changelog

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
