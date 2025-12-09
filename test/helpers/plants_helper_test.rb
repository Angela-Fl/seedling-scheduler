require "test_helper"

class PlantsHelperTest < ActionView::TestCase
  test "format_offset with positive days" do
    assert_equal "5 days after frost", format_offset(5)
  end

  test "format_offset with negative days" do
    assert_equal "10 days before frost", format_offset(-10)
  end

  test "format_offset with weeks divisible by 7" do
    assert_equal "2 weeks before frost", format_offset(-14)
    assert_equal "3 weeks after frost", format_offset(21)
  end

  test "format_offset with single week" do
    assert_equal "1 week before frost", format_offset(-7)
  end

  test "format_offset with nil" do
    assert_equal "", format_offset(nil)
  end

  test "sowing_method_badge returns correct color for direct_sow" do
    badge = sowing_method_badge("direct_sow")
    assert_includes badge, "badge"
    assert_includes badge, "background-color: #a2cf8f"
    assert_includes badge, "color: #000000"
    assert_includes badge, "Direct Sow"
  end

  test "sowing_method_badge returns correct color for indoor_start" do
    badge = sowing_method_badge("indoor_start")
    assert_includes badge, "badge"
    assert_includes badge, "background-color: #e9b38e"
    assert_includes badge, "color: #000000"
    assert_includes badge, "Indoor Start"
  end

  test "sowing_method_badge returns correct color for outdoor_start" do
    badge = sowing_method_badge("outdoor_start")
    assert_includes badge, "badge"
    assert_includes badge, "background-color: #de8ca0"
    assert_includes badge, "color: #000000"
    assert_includes badge, "Outdoor Start"
  end

  test "sowing_method_badge returns correct color for fridge_stratify" do
    badge = sowing_method_badge("fridge_stratify")
    assert_includes badge, "badge"
    assert_includes badge, "background-color: #6c757d"
    assert_includes badge, "color: #ffffff"
    assert_includes badge, "Fridge Stratify"
  end

  test "sowing_method_badge handles unknown method" do
    badge = sowing_method_badge("unknown_method")
    assert_includes badge, "badge"
    assert_includes badge, "background-color: #6c757d"
    assert_includes badge, "color: #ffffff"
  end
end
