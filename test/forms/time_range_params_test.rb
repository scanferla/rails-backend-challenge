require "test_helper"

class TimeRangeParamsTest < ActiveSupport::TestCase
  setup do
    @monday = Time.zone.now.next_week(:monday)
  end

  test "valid with proper ISO8601 from/to and to after from" do
    params = TimeRangeParams.new(from: @monday.change(hour: 9, min: 0).iso8601, to: @monday.change(hour: 10, min: 0).iso8601)

    assert params.valid?
    assert_instance_of Time, params.from
    assert_instance_of Time, params.to
  end

  test "invalid when missing from or to" do
    params_missing = TimeRangeParams.new(from: nil, to: nil)

    assert_not params_missing.valid?
    assert params_missing.errors.of_kind?(:from, :blank)
    assert params_missing.errors.of_kind?(:to, :blank)
  end

  test "invalid when to is not after from" do
    equal_time = @monday.change(hour: 10, min: 0).iso8601
    params_equal = TimeRangeParams.new(from: equal_time, to: equal_time)

    assert_not params_equal.valid?
    assert params_equal.errors.of_kind?(:to, :greater_than)
  end

  test "clamps from to now when from is in the past" do
    past_from = 1.day.ago.iso8601
    future_to = 1.hour.from_now.iso8601
    params_clamped = TimeRangeParams.new(from: past_from, to: future_to)

    assert params_clamped.valid?
    assert params_clamped.from >= Time.zone.now - 1.second # allow tiny drift
  end

  test "to must be in the future (implicit via to > clamped from)" do
    params_with_to_before_from = TimeRangeParams.new(from: 1.minute.from_now.iso8601, to: 1.second.from_now.iso8601)

    assert_not params_with_to_before_from.valid?
    assert params_with_to_before_from.errors.of_kind?(:to, :greater_than)
  end

  test "when only from is missing shows presence error only" do
    params_only_to = TimeRangeParams.new(from: nil, to: 1.hour.from_now.iso8601)

    assert_not params_only_to.valid?
    assert params_only_to.errors.of_kind?(:from, :blank)
    refute params_only_to.errors.of_kind?(:to, :greater_than)
  end

  test "when only to is missing shows presence error only" do
    params_only_from = TimeRangeParams.new(from: 1.hour.from_now.iso8601, to: nil)

    assert_not params_only_from.valid?
    assert params_only_from.errors.of_kind?(:to, :blank)
    refute params_only_from.errors.of_kind?(:to, :greater_than)
  end
end
