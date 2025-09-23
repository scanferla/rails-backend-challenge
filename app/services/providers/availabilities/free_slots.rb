# This service is responsible for the business logic of building truly free slot windows for a provider
# in a given time range. It takes recurring availabilities (from Query), expands them into concrete
# date/time intervals, clamps them to the requested range, and subtracts out any overlapping appointments.
# This separation of concerns keeps the query logic efficient and focused, while allowing all business
# rules and edge cases to be handled in one place. This approach is idiomatic Rails, supports maintainability,
# and directly maps to the challenge requirements: the API returns only truly free, bookable slots.

module Providers
  module Availabilities
    class FreeSlots < ApplicationService
      include DateHelpers

      def initialize(provider:, from:, to:)
        @provider = provider
        @from = from
        @to = to
      end

      def call
        # Query for all availabilities that could possibly overlap the range
        query = Query.call(provider:, from:, to:)
        return failure(error: "availability lookup failed") unless query.success?

        availabilities = query.data[:availabilities]
        # Expand recurring availabilities into concrete windows for each date
        occurrences = expand_occurrences(availabilities)
        # Clamp each window to the requested range (so we never return more than asked)
        clamped = clamp_occurrences(occurrences)
        # Remove zero-length intervals (can happen after clamping, e.g. slot ends exactly at the query start)
        clamped = clamped.reject { |occurrence| occurrence[:starts_at] == occurrence[:ends_at] }
        # Find all scheduled appointments that overlap the requested range
        busy = provider.appointments.scheduled.overlapping(from, to)
        # Subtract busy times from available windows to get truly free slots
        unmerged_free_slots = subtract_appointments(occurrences: clamped, appointments: busy)
        free_slots = merge_intervals(unmerged_free_slots)

        success(free_slots:)
      end

      private

      attr_reader :provider, :from, :to

      # For each date, expand availabilities into concrete time windows
      # Handles recurring weekly slots and overnight/multi-day windows
      def expand_occurrences(availabilities)
        dates_in_scope(from:, to:).flat_map do |date|
          availabilities.select { |a| date.wday == a.start_dow }.filter_map do |availability|
            window_start = at_time_on(date: date, time_of_day: availability.start_time)
            window_end = at_time_on(date: date + availability.days_until_end, time_of_day: availability.end_time)
            # Only include windows that actually overlap the requested range
            next if window_end <= from || window_start >= to

            { starts_at: window_start, ends_at: window_end }
          end
        end
      end

      # Clamp each occurrence to the requested range, so we only return the part that's actually available
      # (if a slot is 09:00-11:00 and you ask for 10:00-12:00, you get 10:00-11:00)
      def clamp_occurrences(occurrences)
        occurrences.map do |occurrence|
          {
            starts_at: [ occurrence[:starts_at], from ].max,
            ends_at: [ occurrence[:ends_at], to ].min
          }
        end
      end

      # Subtract out all busy times (appointments) from the available windows
      # This is the heart of "free slot" logic: split windows around appointments
      def subtract_appointments(occurrences:, appointments:)
        occurrences.flat_map do |occurrence|
          subtract_from_interval(occurrence:, appointments:)
        end
      end

      # For a single window, split it into free periods around any overlapping appointments
      # Handles multiple overlapping appointments and edge cases (e.g. back-to-back bookings)
      def subtract_from_interval(occurrence:, appointments:)
        interval_start = occurrence[:starts_at]
        interval_end = occurrence[:ends_at]

        # Find all appointments that overlap this window
        overlapping = appointments.select do |appointment|
          appointment.starts_at < interval_end && appointment.ends_at > interval_start
        end
        # If no overlaps, the whole window is free
        if overlapping.empty?
          return [ build_interval(starts_at: interval_start, ends_at: interval_end) ]
        end

        free_periods = []
        current_start = interval_start

        # Sort appointments by start time to process in order
        overlapping.sort_by(&:starts_at).each do |appointment|
          busy_start = [ appointment.starts_at, interval_start ].max
          busy_end = [ appointment.ends_at, interval_end ].min

          # Add free period before this appointment, if any
          if current_start < busy_start
            free_periods << build_interval(starts_at: current_start, ends_at: busy_start)
          end

          # Move current_start past this appointment
          current_start = [ current_start, busy_end ].max
        end

        # Add any remaining free period after the last appointment
        if current_start < interval_end
          free_periods << build_interval(starts_at: current_start, ends_at: interval_end)
        end
        free_periods
      end

      # Merge contiguous or overlapping intervals to produce a normalized set
      def merge_intervals(intervals)
        return intervals if intervals.empty?

        sorted = intervals.sort_by { |i| [ i[:starts_at], i[:ends_at] ] }
        merged = [ sorted.first.dup ]

        sorted.drop(1).each do |curr|
          last = merged.last
          if curr[:starts_at] <= last[:ends_at]
            # overlap or touch: extend
            last[:ends_at] = [ last[:ends_at], curr[:ends_at] ].max
          else
            merged << curr.dup
          end
        end
        merged
      end

      # Returns a hash with only starts_at and ends_at; formatting is left to the view layer
      def build_interval(starts_at:, ends_at:)
        { starts_at:, ends_at: }
      end

      # Combine a date and a time-of-day into a Time object in the app's timezone
      # This is needed because availabilities are stored as day-of-week + time-of-day
      def at_time_on(date:, time_of_day:)
        Time.zone.local(date.year, date.month, date.day, time_of_day.hour, time_of_day.min, time_of_day.sec)
      end
    end
  end
end
