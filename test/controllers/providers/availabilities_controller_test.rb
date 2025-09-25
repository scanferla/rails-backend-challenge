require "test_helper"
class Providers::AvailabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @provider = create(:provider, id: 1)
    AvailabilitySync.call(provider_id: @provider.id)
  end

  test "GET /providers/:provider_id/availabilities returns free slots (happy path)" do
    base_monday = Time.zone.now.next_week(:monday)
    from_time = base_monday.change(hour: 9, min: 0)
    to_time   = base_monday.change(hour: 12, min: 0)

    get provider_availabilities_path(@provider), params: { from: from_time.strftime("%Y-%m-%d %H:%M"), to: to_time.strftime("%Y-%m-%d %H:%M") }
    assert_response :success

    body = JSON.parse(@response.body)
    assert_schema "providers_availabilities_index.json", body
    assert_equal @provider.id, body["provider_id"]
    assert_equal from_time.iso8601, body["from"]
    assert_equal to_time.iso8601, body["to"]

    slots = body["free_slots"]
    expect1 = { "starts_at" => base_monday.change(hour: 9,  min: 0).iso8601,  "ends_at" => base_monday.change(hour: 9,  min: 30).iso8601 }
    expect2 = { "starts_at" => base_monday.change(hour: 9,  min: 45).iso8601, "ends_at" => base_monday.change(hour: 10, min: 15).iso8601 }
    expect3 = { "starts_at" => base_monday.change(hour: 11, min: 30).iso8601, "ends_at" => base_monday.change(hour: 12, min: 0).iso8601 }
    assert_includes slots, expect1
    assert_includes slots, expect2
    assert_includes slots, expect3
  end

  test "GET returns 422 for invalid params" do
    get provider_availabilities_path(@provider), params: { from: nil, to: nil }
    assert_response :unprocessable_content

    body = JSON.parse(@response.body)
    assert body["error"].present?
  end

  test "GET returns 404 for unknown provider" do
    get provider_availabilities_path(provider_id: 9999), params: { from: "2025-09-22 09:00", to: "2025-09-22 12:00" }
    assert_response :not_found

    body = JSON.parse(@response.body)
    assert body["error"].present?
  end

  test "GET excludes slots that end exactly at from (no touch-only)" do
    base_monday = Time.zone.now.next_week(:monday)
    from_time = base_monday.change(hour: 10, min: 15) # ends_at of 09:45-10:15
    to_time = base_monday.change(hour: 10, min: 30)

    get provider_availabilities_path(@provider), params: { from: from_time.strftime("%Y-%m-%d %H:%M"), to: to_time.strftime("%Y-%m-%d %H:%M") }
    assert_response :success

    body = JSON.parse(@response.body)
    assert_schema "providers_availabilities_index.json", body
    assert_equal [], body["free_slots"]
  end

  test "GET excludes slots that start exactly at to (no touch-only)" do
    base_monday = Time.zone.now.next_week(:monday)
    from_time = base_monday.change(hour: 8,  min: 30)
    to_time = base_monday.change(hour: 9,  min: 0) # starts_at of 09:00-09:30

    get provider_availabilities_path(@provider), params: { from: from_time.strftime("%Y-%m-%d %H:%M"), to: to_time.strftime("%Y-%m-%d %H:%M") }
    assert_response :success

    body = JSON.parse(@response.body)
    assert_schema "providers_availabilities_index.json", body
    assert_equal [], body["free_slots"]
  end
end
