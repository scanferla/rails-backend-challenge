require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  test "belongs to client and provider" do
    appointment = create(:appointment)

    assert appointment.client
    assert appointment.provider
  end

  test "ends_at must be after starts_at" do
    appointment = build(
      :appointment,
      starts_at: "2025-09-22 10:00",
      ends_at: "2025-09-22 09:59",
      status: :scheduled
    )

    assert_not appointment.valid?
    assert_includes appointment.errors[:ends_at], "must be after starts_at"
  end

  test "status invalid is a validation error (enum validate: true)" do
    appointment = build(:appointment, status: "invalid_status")

    assert_not appointment.valid?
    assert_includes appointment.errors[:status], "is not included in the list"
  end

  test "status enum prefixed helpers work" do
    appointment = build(
      :appointment,
      starts_at: "2025-09-22 10:00",
      ends_at: "2025-09-22 10:30"
    )

    assert appointment.status_scheduled?

    appointment.status_canceled!

    assert appointment.status_canceled?
  end

  test "presence validation for starts_at" do
    appointment = build(:appointment, starts_at: nil)

    assert_not appointment.valid?
    assert_includes appointment.errors[:starts_at], "can't be blank"
  end

  test "presence validation for ends_at" do
    appointment = build(:appointment, ends_at: nil)

    assert_not appointment.valid?
    assert_includes appointment.errors[:ends_at], "can't be blank"
  end

  test "presence validation for status" do
    appointment = build(:appointment, status: nil)

    assert_not appointment.valid?
    assert_includes appointment.errors[:status], "can't be blank"
  end
end
