# This service is responsible solely for efficiently fetching recurring availabilities for a provider
# that could possibly overlap a given time range. It does not expand these into concrete date/time windows;
# that responsibility is delegated to downstream business logic (e.g., FreeSlots).
# This separation of concerns keeps the query logic efficient, testable, and focused, and allows
# business rules (like clamping, splitting, and subtracting appointments) to evolve independently.
# This approach is idiomatic Rails, supports maintainability, and directly maps to the challenge requirements:
# - Query: fetch relevant availabilities
# - FreeSlots: build actual free slot windows, subtracting appointments, and clamping to the requested range.

module Providers
  module Availabilities
    class Query < ApplicationService
      include DateHelpers

      def initialize(provider:, from:, to:)
        @provider = provider
        @from = from
        @to = to
      end

      def call
        availabilities = availabilities_for_days.select { |availability| overlaps_range?(availability) }
        success(availabilities:)
      end

      private

      attr_reader :provider, :from, :to

      # Fetches availabilities that could possibly overlap the range, by day
      def availabilities_for_days
        provider.availabilities.where(
          "start_day_of_week IN (?) OR end_day_of_week IN (?)",
          days_in_scope,
          days_in_scope
        )
      end

      # All unique weekdays in the date range (including the day before, for overnight slots)
      def days_in_scope
        dates_in_scope(from:, to:).map(&:wday).uniq
      end

      # Checks if any instance of this availability overlaps the requested time window
      def overlaps_range?(availability)
        dates_in_scope(from:, to:).any? do |date|
          # Only consider windows that start on this date
          next unless date.wday == availability.start_dow

          window_start = at_time_on(date, availability.start_time)
          window_end = at_time_on(date + availability.days_until_end, availability.end_time)

          # Classic interval overlap: does this window intersect the requested range?
          window_start < to && window_end > from
        end
      end

      # Combines a date and a time-of-day into a Time object in the app's timezone
      def at_time_on(date, time_of_day)
        Time.zone.local(date.year, date.month, date.day, time_of_day.hour, time_of_day.min, time_of_day.sec)
      end
    end
  end
end
