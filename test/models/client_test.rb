require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "has many appointments" do
    client = create(:client)
    provider = create(:provider, id: 1)
    AvailabilitySync.call(provider_id: provider.id)

    next_monday = Time.zone.now.next_week(:monday)
    create(:appointment, client:, provider:, starts_at: next_monday.change(hour: 9, min: 5), ends_at: next_monday.change(hour: 9, min: 25))
    create(:appointment, client:, provider:, starts_at: next_monday.change(hour: 9, min: 45), ends_at: next_monday.change(hour: 10, min: 0))

    assert_equal 2, client.appointments.count
  end

  test "restrict destroy when client has appointments" do
    client = create(:client)
    provider = create(:provider, id: 1)
    AvailabilitySync.call(provider_id: provider.id)

    next_monday = Time.zone.now.next_week(:monday)
    create(:appointment, client:, provider:, starts_at: next_monday.change(hour: 9, min: 5), ends_at: next_monday.change(hour: 9, min: 25))

    assert_no_difference("Appointment.count") do
      assert_not client.destroy, "expected destroy to be restricted"
      assert_includes client.errors.full_messages, "Cannot delete record because dependent appointments exist"
    end
  end
end
