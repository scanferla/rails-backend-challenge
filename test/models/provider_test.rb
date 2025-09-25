require "test_helper"

class ProviderTest < ActiveSupport::TestCase
  test "has many appointments" do
    provider = create(:provider, id: 1)
    AvailabilitySync.call(provider_id: provider.id)

    next_monday = Time.zone.now.next_week(:monday)
    create(:appointment, provider:, client: create(:client), starts_at: next_monday.change(hour: 9, min: 5), ends_at: next_monday.change(hour: 9, min: 25))
    create(:appointment, provider:, client: create(:client), starts_at: next_monday.change(hour: 11, min: 30), ends_at: next_monday.change(hour: 11, min: 45))

    assert_equal 2, provider.appointments.count
  end

  test "has many availabilities" do
    provider = create(:provider)

    create(:availability, provider:)
    create(:availability, provider:)

    assert_equal 2, provider.availabilities.count
  end

  test "restrict destroy when provider has dependents" do
    provider = create(:provider, id: 1)
    AvailabilitySync.call(provider_id: provider.id)
    client = create(:client)
    next_monday = Time.zone.now.next_week(:monday)
    create(:appointment, provider:, client:, starts_at: next_monday.change(hour: 9, min: 5), ends_at: next_monday.change(hour: 9, min: 25))

    assert_no_difference("Appointment.count") do
      assert_not provider.destroy, "expected destroy to be restricted"
      assert_includes provider.errors.full_messages, "Cannot delete record because dependent availabilities exist"
    end
  end

  test "restrict destroy when provider has availabilities" do
    provider = create(:provider)
    create(:availability, provider:)

    assert_not provider.destroy, "expected destroy to be restricted"
    assert_includes provider.errors.full_messages, "Cannot delete record because dependent availabilities exist"
  end
end
