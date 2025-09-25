require "test_helper"

class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @provider = create(:provider, id: 1)
    @client = create(:client)
    AvailabilitySync.call(provider_id: @provider.id)
    @monday = Time.zone.now.next_week(:monday)
  end

  test "POST /appointments creates when inside free slot" do
    starts_at = @monday.change(hour: 9, min: 5)
    ends_at= @monday.change(hour: 9, min: 25)

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

  test "POST /appointments returns 422 for invalid time range" do
    post appointments_path, params: { appointment: { client_id: @client.id, provider_id: @provider.id, starts_at: nil, ends_at: nil } }
    assert_response :unprocessable_content

    body = JSON.parse(@response.body)
    assert body["error"].present?
  end

  test "POST /appointments returns 400 when appointment param missing" do
    post appointments_path, params: {}
    assert_response :bad_request

    body = JSON.parse(@response.body)
    assert_match /param is missing/, body["error"].to_s
  end

  test "POST /appointments returns 422 for conflict" do
    # Existing appointment inside the 9:00-9:30 slot
    create(:appointment, client: @client, provider: @provider, starts_at: @monday.change(hour: 9, min: 10), ends_at: @monday.change(hour: 9, min: 20))

    # Try to book overlapping window
    post appointments_path, params: { appointment: { client_id: @client.id, provider_id: @provider.id, starts_at: @monday.change(hour: 9, min: 0), ends_at: @monday.change(hour: 9, min: 30) } }
    assert_response :unprocessable_content

    body = JSON.parse(@response.body)
    assert body["error"].present?
  end

  test "POST /appointments allows touching edges (no overlap) within same availability" do
    # Use a long slot 16:30-17:30 (from fixture)
    create(:appointment, client: @client, provider: @provider, starts_at: @monday.change(hour: 16, min: 30), ends_at: @monday.change(hour: 17, min: 0))

    # Touching start at 17:00 (no overlap), still inside 16:30-17:30 window
    post appointments_path, params: { appointment: { client_id: @client.id, provider_id: @provider.id, starts_at: @monday.change(hour: 17, min: 0), ends_at: @monday.change(hour: 17, min: 15) } }
    assert_response :created
  end

  test "POST /appointments allows booking exactly the full availability window" do
    starts_at = @monday.change(hour: 9, min: 0)
    ends_at = @monday.change(hour: 9, min: 30)

    post appointments_path, params: { appointment: { client_id: @client.id, provider_id: @provider.id, starts_at:, ends_at: } }
    assert_response :created
  end

  test "POST /appointments rejects booking that exceeds availability by one minute (422)" do
    starts_at = @monday.change(hour: 9, min: 0)
    ends_at = @monday.change(hour: 9, min: 31)

    post appointments_path, params: { appointment: { client_id: @client.id, provider_id: @provider.id, starts_at:, ends_at: } }
    assert_response :unprocessable_content

    body = JSON.parse(@response.body)
    assert body["error"].present?
  end

  test "DELETE /appointments/:id soft-cancels and returns updated resource" do
    appt = create(:appointment, client: @client, provider: @provider, starts_at: @monday.change(hour: 9, min: 0), ends_at: @monday.change(hour: 9, min: 30))

    delete appointment_path(appt)
    assert_response :ok

    body = JSON.parse(@response.body)
    assert_schema "appointments_show.json", body
    assert_equal "canceled", body["status"]
    assert_equal appt.id, body["id"]
  end

  test "DELETE /appointments/:id returns 404 when not found" do
    delete appointment_path(999_999)
    assert_response :not_found

    body = JSON.parse(@response.body)
    assert body["error"].present?
  end
end
