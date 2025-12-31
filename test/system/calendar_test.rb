require "application_system_test_case"

class CalendarTest < ApplicationSystemTestCase
  test "visiting calendar page displays calendar" do
    visit calendar_tasks_path

    # Verify calendar controller is connected
    assert_selector "[data-controller='calendar']"

    # Wait for calendar to fully render
    sleep 2

    # Verify calendar grid is present
    assert_selector ".fc-daygrid", wait: 5

    # Verify current month is displayed
    assert_text Date.today.strftime("%B %Y")

    # FullCalendar buttons use lowercase text
    assert_selector ".fc-today-button", text: "today", wait: 3
  end

  test "clicking date opens task creation modal" do
    visit calendar_tasks_path

    # Wait for calendar to fully render
    sleep 2

    # Find and click a date cell in the calendar
    # Use more specific selector for clickable date
    find(".fc-daygrid-day-frame", match: :first).click

    # Modal should appear - increased wait time
    assert_selector "#taskModal.show", wait: 5

    # Verify modal has the correct title
    within "#taskModal" do
      assert_text "Garden Task"
    end

    # Verify modal has the form fields
    assert_field "task_due_date", wait: 2
    assert_field "task_notes"
    assert_field "task_status"
  end

  test "calendar create button opens modal with current date" do
    visit calendar_tasks_path

    # Wait for calendar to render
    sleep 2

    # Click the "+ New Task" button which triggers calendar:create event
    click_button "+ New Task"

    # Wait for modal to appear
    assert_selector "#taskModal.show", wait: 5

    # Verify the modal opened with form fields
    within "#taskModal" do
      assert_text "Garden Task"
      assert_field "task_due_date"
      assert_field "task_notes"
      assert_select "task_status"
    end
  end

  test "view switcher changes calendar layout" do
    visit calendar_tasks_path

    # Wait for calendar to render
    sleep 2

    # Verify we start in month view
    assert_selector ".fc-daygrid", wait: 5

    # FullCalendar uses button elements with specific classes
    # Click the year view button by finding the button with the view name
    find("button.fc-multiMonthYear-button").click

    # Wait for view to change
    sleep 2

    # Should show multi-month view
    assert_selector ".fc-multimonth", wait: 5

    # Switch back to month view
    find("button.fc-dayGridMonth-button").click

    # Wait for view to change
    sleep 2

    # Should show day grid again
    assert_selector ".fc-daygrid", wait: 5
  end

  test "calendar displays existing tasks" do
    # Create a task in the database
    task = Task.create!(
      user: users(:one),
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
    sleep 2

    # Click next month a few times to navigate away
    3.times do
      find(".fc-next-button").click
      sleep 0.5
    end

    # Click "Today" button - it's a div with class fc-today-button
    find(".fc-today-button").click

    sleep 1

    # Should display current month
    assert_text Date.today.strftime("%B %Y"), wait: 3
  end
end
