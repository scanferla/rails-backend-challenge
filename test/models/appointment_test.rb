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
    assert appointment.errors.of_kind?(:ends_at, :greater_than)
  end

  test "status invalid is a validation error (enum validate: true)" do
    appointment = build(:appointment, status: "invalid_status")

    assert_not appointment.valid?
    assert appointment.errors.of_kind?(:status, :inclusion)
  end

  test "status enum helpers work" do
    appointment = build(
      :appointment,
      starts_at: "2025-09-22 10:00",
      ends_at: "2025-09-22 10:30"
    )

    assert appointment.scheduled?

    appointment.canceled!

    assert appointment.canceled?
  end

  test "presence validation for starts_at" do
    appointment = build(:appointment, starts_at: nil)

    assert_not appointment.valid?
    assert appointment.errors.of_kind?(:starts_at, :blank)
  end

  test "presence validation for ends_at" do
    appointment = build(:appointment, ends_at: nil)

    assert_not appointment.valid?
    assert appointment.errors.of_kind?(:ends_at, :blank)
  end

  test "presence validation for status" do
    appointment = build(:appointment, status: nil)

    assert_not appointment.valid?
    assert appointment.errors.of_kind?(:status, :blank)
  end

  test "overlapping scope returns appointments that intersect window" do
    provider = create(:provider)
    create(:client)

    inside = create(:appointment, provider:, starts_at: "2025-09-22 10:00", ends_at: "2025-09-22 11:00")
    touching_end = create(:appointment, provider:, starts_at: "2025-09-22 12:00", ends_at: "2025-09-22 13:00")
    touching_start = create(:appointment, provider:, starts_at: "2025-09-22 08:00", ends_at: "2025-09-22 09:00")

    results = Appointment.where(provider:).overlapping(Time.zone.parse("2025-09-22 09:00"), Time.zone.parse("2025-09-22 12:00"))

    assert_includes results, inside
    refute_includes results, touching_end
    refute_includes results, touching_start
  end
end
