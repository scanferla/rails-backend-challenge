require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "has many appointments" do
    client = create(:client)

    create(:appointment, client:)
    create(:appointment, client:)

    assert_equal 2, client.appointments.count
  end
end
