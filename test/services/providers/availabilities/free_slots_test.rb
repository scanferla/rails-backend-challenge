require "test_helper"

class Providers::Availabilities::FreeSlotsTest < ActiveSupport::TestCase
  setup do
    @provider = create(:provider, id: 1)
    AvailabilitySync.call(provider_id: @provider.id)
    @client = create(:client)
    @next_monday = Time.zone.now.next_week(:monday)
  end

  test "clamps a single window to the requested range" do
    from = "2025-09-22 09:05" # Monday
    to = "2025-09-22 09:25"

    result = Providers::Availabilities::FreeSlots.call(provider: @provider, from:, to:)
    assert result.success?

    slots = result.data[:free_slots]
    assert_includes slots, { starts_at: from, ends_at: to }
  end

  test "splits around an overlapping appointment" do
    # Window is 09:00–09:30; add appointment 09:10–09:20
    create(:appointment, provider: @provider, client: @client,
                         starts_at: @next_monday.change(hour: 9, min: 10), ends_at: @next_monday.change(hour: 9, min: 20))

    from = @next_monday.change(hour: 9, min: 0)
    to = @next_monday.change(hour: 9, min: 30)

    result = Providers::Availabilities::FreeSlots.call(provider: @provider, from:, to:)
    assert result.success?

    slots = result.data[:free_slots]
    assert_includes slots, { starts_at: from, ends_at: @next_monday.change(hour: 9, min: 10) }
    assert_includes slots, { starts_at: @next_monday.change(hour: 9, min: 20), ends_at: to }
  end

  test "returns cross-midnight window portion" do
    from = @next_monday.change(hour: 23, min: 45)
    to = (@next_monday + 1.day).change(hour: 0, min: 30)

    result = Providers::Availabilities::FreeSlots.call(provider: @provider, from:, to:)
    assert result.success?

    slots = result.data[:free_slots]
    assert_includes slots, { starts_at: from, ends_at: (@next_monday + 1.day).change(hour: 0, min: 15) }
  end

  test "edge-touching appointments do not subtract time" do
    # Query 09:10–09:20; busy 09:00–09:10 and 09:20–09:30 touch the edges but do not reduce inside
    create(:appointment, provider: @provider, client: @client,
                         starts_at: @next_monday.change(hour: 9, min: 0), ends_at: @next_monday.change(hour: 9, min: 10))
    create(:appointment, provider: @provider, client: @client,
                         starts_at: @next_monday.change(hour: 9, min: 20), ends_at: @next_monday.change(hour: 9, min: 30))

    from = @next_monday.change(hour: 9, min: 10)
    to = @next_monday.change(hour: 9, min: 20)

    result = Providers::Availabilities::FreeSlots.call(provider: @provider, from:, to:)
    assert result.success?

    slots = result.data[:free_slots]
    assert_includes slots, { starts_at: from, ends_at: to }
  end

  test "drops zero-length after clamp" do
    # Range ends exactly at 09:00; window starts at 09:00
    from = @next_monday.change(hour: 8, min: 0)
    to = @next_monday.change(hour: 9, min: 0)

    result = Providers::Availabilities::FreeSlots.call(provider: @provider, from:, to:)
    assert result.success?

    slots = result.data[:free_slots]

    # No slot starts at 09:00 exactly in the fixture? Ensure no zero-length records anyway
    refute_includes slots, { starts_at: to, ends_at: to }
  end

  test "splits around two overlapping appointments" do
    # Window 11:30–12:00; add apts 11:35–11:40 and 11:45–11:50
    create(:appointment, provider: @provider, client: @client,
                         starts_at: @next_monday.change(hour: 11, min: 35), ends_at: @next_monday.change(hour: 11, min: 40))
    create(:appointment, provider: @provider, client: @client,
                         starts_at: @next_monday.change(hour: 11, min: 45), ends_at: @next_monday.change(hour: 11, min: 50))

    from = @next_monday.change(hour: 11, min: 30)
    to = @next_monday.change(hour: 12, min: 0)

    result = Providers::Availabilities::FreeSlots.call(provider: @provider, from:, to:)
    assert result.success?

    slots = result.data[:free_slots]

    assert_includes slots, { starts_at: from, ends_at: @next_monday.change(hour: 11, min: 35) }
    assert_includes slots, { starts_at: @next_monday.change(hour: 11, min: 40), ends_at: @next_monday.change(hour: 11, min: 45) }
    assert_includes slots, { starts_at: @next_monday.change(hour: 11, min: 50), ends_at: to }
  end

  test "merges contiguous windows into a single slot" do
    provider = create(:provider, id: 3)
    AvailabilitySync.call(provider_id: provider.id)

    from = "2025-09-25 10:00" # Thursday
    to = "2025-09-25 11:30"

    result = Providers::Availabilities::FreeSlots.call(provider:, from:, to:)
    assert result.success?

    slots = result.data[:free_slots]
    assert_includes slots, { starts_at: from, ends_at: to }
    # Should not return the two separate touching windows
    refute_includes slots, { starts_at: "2025-09-25 10:00", ends_at: "2025-09-25 11:00" }
    refute_includes slots, { starts_at: "2025-09-25 11:00", ends_at: "2025-09-25 11:30" }
  end
end
