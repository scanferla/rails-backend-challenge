class Appointment < ApplicationRecord
  belongs_to :client
  belongs_to :provider

  enum :status, {
    scheduled: "scheduled",
    canceled: "canceled"
  }, default: :scheduled, validate: true

  validates :starts_at, :ends_at, :status, presence: true
  validates :ends_at, comparison: { greater_than: :starts_at, message: "must be after starts_at" }

  # Finds appointments that have actual time overlap (touching edges don't count as overlap)
  scope :overlapping, ->(from_time, to_time) {
    where("starts_at < ? AND ends_at > ?", to_time, from_time)
  }
end
