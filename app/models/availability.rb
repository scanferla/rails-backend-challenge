class Availability < ApplicationRecord
  belongs_to :provider

  DAYS_OF_WEEK = {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }.freeze

  enum :start_day_of_week, DAYS_OF_WEEK, prefix: :starts_on, validate: true
  enum :end_day_of_week, DAYS_OF_WEEK, prefix: :ends_on, validate: true

  validates :source,
            :external_id,
            :start_day_of_week,
            :end_day_of_week,
            :start_time,
            :end_time,
            presence: true

  validates :external_id, uniqueness: { scope: %i[provider_id source] }

  validates :end_time,
            comparison: { greater_than: :start_time, message: "must be after start_time for same-day windows" },
            if: -> { start_day_of_week == end_day_of_week }

  def start_dow
    self.class.start_day_of_weeks[start_day_of_week]
  end

  def end_dow
    self.class.end_day_of_weeks[end_day_of_week]
  end

  def days_until_end
    (end_dow - start_dow) % 7
  end
end
