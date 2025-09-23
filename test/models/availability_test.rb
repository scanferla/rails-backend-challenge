require "test_helper"

class AvailabilityTest < ActiveSupport::TestCase
  test "enums accept symbols and generate natural predicates" do
    availability = build(
      :availability,
      start_day_of_week: :monday,
      start_time: "09:00",
      end_day_of_week: :monday,
      end_time: "09:30"
    )

    assert availability.starts_on_monday?
    assert availability.ends_on_monday?
  end

  test "uniqueness on provider+source+external_id" do
    existing = create(:availability, source: "calendly", external_id: "dup-1")

    dup = build(
      :availability,
      provider: existing.provider,
      source: existing.source,
      external_id: existing.external_id,
      start_day_of_week: :monday,
      start_time: "10:00",
      end_day_of_week: :monday,
      end_time: "10:30"
    )

    assert_not dup.valid?
    assert dup.errors.of_kind?(:external_id, :taken)
  end

  test "same-day end_time must be after start_time" do
    availability = build(
      :availability,
      source: "calendly",
      external_id: "test-2",
      start_day_of_week: :monday,
      start_time: "09:30",
      end_day_of_week: :monday,
      end_time: "09:00"
    )

    assert_not availability.valid?
    assert availability.errors.of_kind?(:end_time, :greater_than)
  end

  test "presence validations" do
    required_attrs = %i[source external_id start_day_of_week end_day_of_week start_time end_time]

    required_attrs.each do |attr|
      availability = build(:availability)
      availability.send("#{attr}=", nil)

      assert_not availability.valid?, "expected #{attr} presence validation to fail"
      assert availability.errors.of_kind?(attr, :blank)
    end
  end

  test "cross-day window allows end_time before start_time" do
    availability = build(
      :availability,
      start_day_of_week: :monday,
      start_time: "23:30",
      end_day_of_week: :tuesday,
      end_time: "00:15"
    )

    assert availability.valid?
  end

  test "invalid day enum adds validation error" do
    availability = build(:availability, start_day_of_week: :funday)

    assert_not availability.valid?
    assert availability.errors.of_kind?(:start_day_of_week, :inclusion)
  end
end
