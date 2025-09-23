class Appointment < ApplicationRecord
  belongs_to :client
  belongs_to :provider

  enum :status, {
    scheduled: "scheduled",
    canceled: "canceled"
  }, default: :scheduled, validate: true

  validates :starts_at, :ends_at, :status, presence: true
  validates :ends_at, comparison: { greater_than: :starts_at, message: "must be after starts_at" }

  validate :fits_in_free_slot, if: :time_window_changed?

  # Finds appointments that have actual time overlap (touching edges don't count as overlap)
  scope :overlapping, ->(from_time, to_time) {
    where("starts_at < ? AND ends_at > ?", to_time, from_time)
  }

  private

  def time_window_changed?
    will_save_change_to_starts_at? || will_save_change_to_ends_at?
  end

  def fits_in_free_slot
    return if provider.blank? || starts_at.blank? || ends_at.blank?

    # Prevent double-booking under concurrency
    provider.with_lock do
      result = Providers::Availabilities::FreeSlots.call(provider:, from: starts_at, to: ends_at)

      free_slots = result.data[:free_slots] if result.success?
      fits = free_slots.try(:any?) { |slot| slot[:starts_at] <= starts_at && slot[:ends_at] >= ends_at }

      errors.add(:base, "no availability for requested time") unless fits
    end
  end
end
