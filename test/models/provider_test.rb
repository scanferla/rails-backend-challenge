require "test_helper"

class ProviderTest < ActiveSupport::TestCase
  test "has many appointments" do
    provider = create(:provider)

    create(:appointment, provider:)
    create(:appointment, provider:)

    assert_equal 2, provider.appointments.count
  end

  test "has many availabilities" do
    provider = create(:provider)

    create(:availability, provider:)
    create(:availability, provider:)

    assert_equal 2, provider.availabilities.count
  end
end
