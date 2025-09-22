require "test_helper"

class AvailabilitySyncTest < ActiveSupport::TestCase
  setup do
    create(:provider, id: 1)
  end

  test "creates and is idempotent for provider 1 and returns counts" do
    result1 = AvailabilitySync.call(provider_id: 1)
    
    assert result1.success?
    assert_equal({ created: 9, updated: 0, unchanged: 0, total: 9 }, result1.data[:counts])

    # Second run should not create duplicates or updates
    assert_no_difference -> { Availability.where(provider_id: 1).count } do
      result2 = AvailabilitySync.call(provider_id: 1)
      assert result2.success?
      assert_equal({ created: 0, updated: 0, unchanged: 9, total: 9 }, result2.data[:counts])
    end
  end

  test "maps days and times from Calendly payload" do
    result = AvailabilitySync.call(provider_id: 1)
    assert result.success?

    early = Availability.find_by!(provider_id: 1, external_id: "p1-slot-early-morning")
    assert early.starts_on_monday?
    assert early.ends_on_monday?
    assert_equal "06:30", early.start_time.strftime("%H:%M")
    assert_equal "07:00", early.end_time.strftime("%H:%M")

    cross = Availability.find_by!(provider_id: 1, external_id: "p1-slot-evening-cross-midnight")
    assert cross.starts_on_monday?
    assert cross.ends_on_tuesday?
  end

  test "creates all slots for provider 2" do
    create(:provider, id: 2)
    result = AvailabilitySync.call(provider_id: 2)
    assert result.success?
    assert_equal 3, Availability.where(provider_id: 2).count
    assert_equal({ created: 3, updated: 0, unchanged: 0, total: 3 }, result.data[:counts])
  end

  test "returns failure and errors on invalid same-day window" do
    bogus_client = Class.new do
      def fetch_slots(_)
        [
          {
            "id" => "bogus-1",
            "source" => "calendly",
            "starts_at" => { "day_of_week" => :monday, "time" => "10:00" },
            "ends_at" => { "day_of_week" => :monday, "time" => "09:00" }
          }
        ]
      end
    end.new

    create(:provider, id: 99)
    result = AvailabilitySync.call(client: bogus_client, provider_id: 99)

    assert_not result.success?

    assert_equal 1, result.error[:counts][:total]
    assert_equal 0, result.error[:counts][:created]
    assert_equal 0, result.error[:counts][:updated]
    assert_equal 0, result.error[:counts][:unchanged]
    assert_equal "bogus-1", result.error[:errors].first[:external_id]
  end

  test "counts updated only when attributes changed" do
    # seed
    AvailabilitySync.call(provider_id: 1)
    to_fix = Availability.find_by!(provider_id: 1, external_id: "p1-slot-morning-1")
    to_fix.update!(end_time: "09:45")

    result = AvailabilitySync.call(provider_id: 1)
    assert result.success?
    assert_equal({ created: 0, updated: 1, unchanged: 8, total: 9 }, result.data[:counts])
  end
end


