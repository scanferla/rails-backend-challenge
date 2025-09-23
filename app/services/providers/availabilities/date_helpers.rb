module Providers
  module Availabilities
    module DateHelpers
      # Include previous day to capture overnight windows
      def dates_in_scope(from:, to:)
        (from.to_date - 1).upto(to.to_date)
      end
    end
  end
end
