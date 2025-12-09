require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "frost_date returns parsed date when setting exists" do
    Setting.where(key: "frost_date").destroy_all
    Setting.create!(key: "frost_date", value: "2026-06-01")
    assert_equal Date.new(2026, 6, 1), Setting.frost_date
  end

  test "frost_date returns default when setting does not exist" do
    Setting.where(key: "frost_date").destroy_all
    assert_equal Setting::DEFAULT_FROST_DATE, Setting.frost_date
  end

  test "set_frost_date creates new setting" do
    Setting.where(key: "frost_date").destroy_all
    new_date = Date.new(2027, 5, 20)

    Setting.set_frost_date(new_date)

    setting = Setting.find_by(key: "frost_date")
    assert_equal new_date.to_s, setting.value
  end

  test "set_frost_date updates existing setting" do
    Setting.where(key: "frost_date").destroy_all
    Setting.create!(key: "frost_date", value: "2026-05-15")
    new_date = Date.new(2027, 6, 1)

    Setting.set_frost_date(new_date)

    setting = Setting.find_by(key: "frost_date")
    assert_equal new_date.to_s, setting.value
    assert_equal 1, Setting.where(key: "frost_date").count
  end

  test "validates key presence" do
    setting = Setting.new(value: "test")
    assert_not setting.valid?
    assert_includes setting.errors[:key], "can't be blank"
  end

  test "validates key uniqueness" do
    Setting.create!(key: "test_key", value: "value1")
    setting = Setting.new(key: "test_key", value: "value2")
    assert_not setting.valid?
    assert_includes setting.errors[:key], "has already been taken"
  end
end
