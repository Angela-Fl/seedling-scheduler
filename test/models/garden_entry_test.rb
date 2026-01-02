require "test_helper"

class GardenEntryTest < ActiveSupport::TestCase
  test "requires title, entry_date and body" do
    entry = GardenEntry.new
    assert_not entry.valid?
    assert_includes entry.errors[:title], "can't be blank"
    assert_includes entry.errors[:entry_date], "can't be blank"
    assert_includes entry.errors[:body], "can't be blank"
  end
end
