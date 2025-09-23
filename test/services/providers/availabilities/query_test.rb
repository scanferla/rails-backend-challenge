require "test_helper"

class Providers::Availabilities::QueryTest < ActiveSupport::TestCase
  setup do
    @provider = create(:provider, id: 1)
    AvailabilitySync.call(provider_id: @provider.id)
  end

  test "returns all simple Monday slots in range" do
    from = Time.zone.parse("2025-09-22 06:00") # Monday
    to = Time.zone.parse("2025-09-22 18:00")

    result = Providers::Availabilities::Query.call(provider: @provider, from:, to:)
    assert result.success?

    ids = result.data[:availabilities].map(&:external_id)

    assert_includes ids, "p1-slot-early-morning"
    assert_includes ids, "p1-slot-morning-1"
    assert_includes ids, "p1-slot-morning-back-to-back"
    assert_includes ids, "p1-slot-lunch-gap-before"
    assert_includes ids, "p1-slot-lunch-gap-after"
    assert_includes ids, "p1-slot-late-afternoon"
    refute_includes ids, "p1-slot-evening-cross-midnight"
    refute_includes ids, "p1-slot-next-day-morning"
    refute_includes ids, "p1-slot-weekend"
  end

  test "includes overnight slot crossing midnight" do
    from = Time.zone.parse("2025-09-22 23:45") # Monday 23:45
    to = Time.zone.parse("2025-09-23 00:30") # Tuesday 00:30
    
    result = Providers::Availabilities::Query.call(provider: @provider, from:, to:)
    assert result.success?

    ids = result.data[:availabilities].map(&:external_id)

    assert_includes ids, "p1-slot-evening-cross-midnight"
  end

  test "includes next day morning slot only on Tuesday" do
    from = Time.zone.parse("2025-09-23 08:00") # Tuesday
    to = Time.zone.parse("2025-09-23 11:00")

    result = Providers::Availabilities::Query.call(provider: @provider, from:, to:)
    assert result.success?

    ids = result.data[:availabilities].map(&:external_id)

    assert_includes ids, "p1-slot-next-day-morning"
    refute_includes ids, "p1-slot-evening-cross-midnight"
  end

  test "excludes slots outside the range" do
    from = Time.zone.parse("2025-09-22 14:00")
    to = Time.zone.parse("2025-09-22 16:00")

    result = Providers::Availabilities::Query.call(provider: @provider, from:, to:)
    assert result.success?

    ids = result.data[:availabilities].map(&:external_id)

    refute_includes ids, "p1-slot-morning-1"
    refute_includes ids, "p1-slot-evening-cross-midnight"
    refute_includes ids, "p1-slot-next-day-morning"
  end

  test "includes weekend slot only on Saturday" do
    from = Time.zone.parse("2025-09-27 13:00") # Saturday
    to = Time.zone.parse("2025-09-27 16:00")

    result = Providers::Availabilities::Query.call(provider: @provider, from:, to:)
    assert result.success?

    ids = result.data[:availabilities].map(&:external_id)

    assert_includes ids, "p1-slot-weekend"
  end

  test "handles back-to-back and gap slots distinctly" do
    from = Time.zone.parse("2025-09-22 09:00")
    to = Time.zone.parse("2025-09-22 10:30")

    result = Providers::Availabilities::Query.call(provider: @provider, from:, to:)
    assert result.success?
    
    ids = result.data[:availabilities].map(&:external_id)
    
    assert_includes ids, "p1-slot-morning-1"
    assert_includes ids, "p1-slot-morning-back-to-back"
    refute_includes ids, "p1-slot-lunch-gap-before"
  end
end
