require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  setup do
    @next_monday = Time.zone.now.next_week(:monday)
  end

  test "belongs to client and provider" do
    provider = create(:provider, id: 1)
    AvailabilitySync.call(provider_id: provider.id)
    client = create(:client)

    appointment = create(:appointment,
                         provider:,
                         client:,
                         starts_at: @next_monday.change(hour: 9, min: 5),
                         ends_at: @next_monday.change(hour: 9, min: 25))

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
      client: create(:client),
      provider: create(:provider),
      starts_at: "2025-09-22 10:00",
      ends_at: "2025-09-22 10:30",
      status: :scheduled
    )

    assert appointment.scheduled?

    appointment.status = :canceled

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
    provider = create(:provider, id: 3)
    AvailabilitySync.call(provider_id: provider.id)
    client = create(:client)

    # Provider 3 has Thursday 10:00-11:00 and 11:00-11:30
    thursday = Time.zone.now.next_occurring(:thursday)
    inside = create(:appointment, provider:, client:,
                    starts_at: thursday.change(hour: 10, min: 15),
                    ends_at: thursday.change(hour: 10, min: 45))
    touching_end = create(:appointment, provider:, client:,
                          starts_at: thursday.change(hour: 11, min: 0),
                          ends_at: thursday.change(hour: 11, min: 15))

    results = Appointment.where(provider:).overlapping(thursday.change(hour: 10, min: 0), thursday.change(hour: 11, min: 0))

    assert_includes results, inside
    refute_includes results, touching_end
  end

  test "fits_in_free_slot validation passes when inside free slot" do
    provider = create(:provider, id: 1)
    client = create(:client)
    AvailabilitySync.call(provider_id: provider.id)

    appointment = build(
      :appointment,
      client:,
      provider:,
      starts_at: @next_monday.change(hour: 9, min: 5),
      ends_at: @next_monday.change(hour: 9, min: 25)
    )

    assert appointment.valid?
    assert appointment.save

    # Changing the time window should re-run validation and fail if outside
    appointment.starts_at = @next_monday.change(hour: 7, min: 0)
    appointment.ends_at = @next_monday.change(hour: 7, min: 30)
    assert_not appointment.valid?
  end

  test "fits_in_free_slot validation fails when outside free slot" do
    provider = create(:provider, id: 1)
    client = create(:client)
    AvailabilitySync.call(provider_id: provider.id)

    appointment = build(
      :appointment,
      client:,
      provider:,
      starts_at: @next_monday.change(hour: 7, min: 0),
      ends_at: @next_monday.change(hour: 7, min: 30)
    )

    assert_not appointment.valid?
    assert appointment.errors.full_messages.any? { |m| m.include?("no availability") }
  end
end
