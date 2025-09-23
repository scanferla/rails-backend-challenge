require "test_helper"

class TimeRangeParamsTest < ActiveSupport::TestCase
  test "valid with proper ISO8601 from/to and to after from" do
    r = TimeRangeParams.new(from: "2025-10-06T09:00:00Z", to: "2025-10-06T10:00:00Z")
    assert r.valid?
    assert_instance_of Time, r.from
    assert_instance_of Time, r.to
  end

  test "invalid when missing from or to" do
    r = TimeRangeParams.new(from: nil, to: nil)
    assert_not r.valid?
    assert r.errors.of_kind?(:from, :blank)
    assert r.errors.of_kind?(:to, :blank)
  end

  test "invalid when to is not after from" do
    r = TimeRangeParams.new(from: "2025-10-06T10:00:00Z", to: "2025-10-06T10:00:00Z")
    assert_not r.valid?
    assert r.errors.of_kind?(:to, :greater_than)
  end
end
