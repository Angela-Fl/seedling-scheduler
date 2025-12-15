require "application_system_test_case"

class CalendarTest < ApplicationSystemTestCase
  test "visiting calendar page displays calendar" do
    visit calendar_tasks_path

    # Verify calendar controller is connected
    assert_selector "[data-controller='calendar']"

    # Verify current month is displayed
    assert_text Date.today.strftime("%B %Y")

    # Verify calendar toolbar buttons
    assert_button "Today"

    # Give FullCalendar time to render
    sleep 1

    # Verify calendar grid is present
    assert_selector ".fc-daygrid"
  end

  test "clicking date opens task creation modal" do
    visit calendar_tasks_path

    # Wait for calendar to fully render
    sleep 1

    # Find and click a date cell in the calendar
    # Target a date cell that's not disabled
    first(".fc-daygrid-day:not(.fc-day-disabled):not(.fc-day-other)").click

    # Modal should appear
    assert_selector "#taskModal.show", wait: 3

    # Verify modal has the form fields
    assert_field "due_date"
    assert_field "notes"
    assert_select "status"

    # Close modal
    find("button.btn-close").click

    # Modal should disappear
    assert_no_selector "#taskModal.show", wait: 2
  end

  test "creating task from calendar refreshes events" do
    visit calendar_tasks_path

    # Wait for calendar to render
    sleep 1

    # Click on a future date
    first(".fc-daygrid-day:not(.fc-day-disabled):not(.fc-day-other)").click

    # Wait for modal
    assert_selector "#taskModal.show", wait: 2

    within "#taskModal" do
      # Fill in task details
      fill_in "notes", with: "System test garden task"

      # Submit form
      click_button "Save Task"
    end

    # Modal should close
    assert_no_selector "#taskModal.show", wait: 3

    # Success notification should appear
    assert_text "Task saved successfully", wait: 3
  end

  test "view switcher changes calendar layout" do
    visit calendar_tasks_path

    # Wait for calendar to render
    sleep 1

    # Verify we start in month view
    assert_selector ".fc-daygrid"

    # Switch to year view
    click_button "multiMonthYear"

    # Wait for view to change
    sleep 1

    # Should show multi-month view
    assert_selector ".fc-multimonth", wait: 3

    # Switch back to month view
    click_button "dayGridMonth"

    # Wait for view to change
    sleep 1

    # Should show day grid again
    assert_selector ".fc-daygrid", wait: 3
  end

  test "calendar displays existing tasks" do
    # Create a task in the database
    task = Task.create!(
      task_type: "garden_task",
      due_date: Date.today + 7.days,
      status: "pending",
      notes: "Test task for calendar"
    )

    visit calendar_tasks_path

    # Wait for calendar and tasks to load
    sleep 2

    # Task should appear as an event on the calendar
    # FullCalendar uses data-date attributes for date cells
    date_str = task.due_date.strftime("%Y-%m-%d")

    # The event should be visible somewhere on the calendar
    # Note: This is a simplified check - more specific selectors may be needed
    assert_selector ".fc-event", wait: 3
  end

  test "today button navigates to current month" do
    visit calendar_tasks_path

    # Wait for calendar to render
    sleep 1

    # Click next month a few times to navigate away
    3.times do
      find(".fc-next-button").click
      sleep 0.5
    end

    # Click "Today" button
    click_button "Today"

    sleep 1

    # Should display current month
    assert_text Date.today.strftime("%B %Y")
  end
end
