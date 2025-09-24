require "test_helper"

class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @provider = create(:provider, id: 1)
    @client = create(:client)
    AvailabilitySync.call(provider_id: @provider.id)
  end

  test "POST /appointments creates when inside free slot" do
    monday = Time.zone.now.next_week(:monday)
    starts_at = monday.change(hour: 9, min: 5)
    ends_at= monday.change(hour: 9, min: 25)

    post appointments_path, params: { appointment: { client_id: @client.id, provider_id: @provider.id, starts_at:, ends_at: } }
    assert_response :created

    body = JSON.parse(@response.body)
    assert_schema "appointments_show.json", body
    assert_equal @client.id, body["client_id"]
    assert_equal @provider.id, body["provider_id"]
    assert_equal starts_at.iso8601, body["starts_at"]
    assert_equal ends_at.iso8601, body["ends_at"]
    assert_equal "scheduled", body["status"]
  end

  test "POST /appointments returns 400 for invalid time range" do
    post appointments_path, params: { appointment: { client_id: @client.id, provider_id: @provider.id, starts_at: nil, ends_at: nil } }
    assert_response :bad_request

    body = JSON.parse(@response.body)
    assert body["error"].present?
  end

  test "POST /appointments returns 400 when appointment param missing" do
    post appointments_path, params: {}
    assert_response :bad_request

    body = JSON.parse(@response.body)
    assert_match /param is missing/, body["error"].to_s
  end

  test "POST /appointments returns 400 for conflict" do
    monday = Time.zone.now.next_week(:monday)
    # Existing appointment inside the 9:00-9:30 slot
    create(:appointment, client: @client, provider: @provider, starts_at: monday.change(hour: 9, min: 10), ends_at: monday.change(hour: 9, min: 20))

    # Try to book overlapping window
    post appointments_path, params: { appointment: { client_id: @client.id, provider_id: @provider.id, starts_at: monday.change(hour: 9, min: 0), ends_at: monday.change(hour: 9, min: 30) } }
    assert_response :bad_request

    body = JSON.parse(@response.body)
    assert body["error"].present?
  end
end
