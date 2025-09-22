class Appointment < ApplicationRecord
  belongs_to :client
  belongs_to :provider

  enum :status, {
    scheduled: "scheduled",
    canceled: "canceled"
  }, prefix: true, default: :scheduled, validate: true

  validates :starts_at, :ends_at, :status, presence: true
  validates :ends_at, comparison: { greater_than: :starts_at, message: "must be after starts_at" }
end
