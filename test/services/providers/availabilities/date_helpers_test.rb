require "test_helper"

class Providers::Availabilities::DateHelpersTest < ActiveSupport::TestCase
  include Providers::Availabilities::DateHelpers

  test "dates_in_scope includes the day before from and up to to" do
    from = Date.new(2025, 9, 23)
    to = Date.new(2025, 9, 25)

    result = dates_in_scope(from:, to:).to_a

    assert_equal [ Date.new(2025, 9, 22), Date.new(2025, 9, 23), Date.new(2025, 9, 24), Date.new(2025, 9, 25) ], result
  end
end
