require "test_helper"

class Providers::Availabilities::QueryTest < ActiveSupport::TestCase
  setup do
    @provider = create(:provider, id: 1)
    AvailabilitySync.call(provider_id: @provider.id)

    @next_monday = Time.zone.now.next_week(:monday)
    @next_tuesday = Time.zone.now.next_week(:tuesday)
    @next_saturday = Time.zone.now.next_week(:saturday)
  end

  test "returns all simple Monday slots in range" do
    from = @next_monday.change(hour: 6, min: 0)
    to = @next_monday.change(hour: 18, min: 0)

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
    from = @next_monday.change(hour: 23, min: 45)
    to = (@next_monday + 1.day).change(hour: 0, min: 30)

    result = Providers::Availabilities::Query.call(provider: @provider, from:, to:)
    assert result.success?

    ids = result.data[:availabilities].map(&:external_id)

    assert_includes ids, "p1-slot-evening-cross-midnight"
  end

  test "includes next day morning slot only on Tuesday" do
    from = @next_tuesday.change(hour: 8, min: 0)
    to = @next_tuesday.change(hour: 11, min: 0)

    result = Providers::Availabilities::Query.call(provider: @provider, from:, to:)
    assert result.success?

    ids = result.data[:availabilities].map(&:external_id)

    assert_includes ids, "p1-slot-next-day-morning"
    refute_includes ids, "p1-slot-evening-cross-midnight"
  end

  test "excludes slots outside the range" do
    from = @next_monday.change(hour: 14, min: 0)
    to = @next_monday.change(hour: 16, min: 0)

    result = Providers::Availabilities::Query.call(provider: @provider, from:, to:)
    assert result.success?

    ids = result.data[:availabilities].map(&:external_id)

    refute_includes ids, "p1-slot-morning-1"
    refute_includes ids, "p1-slot-evening-cross-midnight"
    refute_includes ids, "p1-slot-next-day-morning"
  end

  test "includes weekend slot only on Saturday" do
    from = @next_saturday.change(hour: 13, min: 0)
    to = @next_saturday.change(hour: 16, min: 0)

    result = Providers::Availabilities::Query.call(provider: @provider, from:, to:)
    assert result.success?

    ids = result.data[:availabilities].map(&:external_id)

    assert_includes ids, "p1-slot-weekend"
  end

  test "handles back-to-back and gap slots distinctly" do
    from = @next_monday.change(hour: 9, min: 0)
    to = @next_monday.change(hour: 10, min: 30)

    result = Providers::Availabilities::Query.call(provider: @provider, from:, to:)
    assert result.success?

    ids = result.data[:availabilities].map(&:external_id)

    assert_includes ids, "p1-slot-morning-1"
    assert_includes ids, "p1-slot-morning-back-to-back"
    refute_includes ids, "p1-slot-lunch-gap-before"
  end
end
