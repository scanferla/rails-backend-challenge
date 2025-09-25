# In production/live code, trigger this via a webhook → background job.
# Optionally prune: delete provider Calendly availabilities whose external_ids are absent in the payload.

class AvailabilitySync < ApplicationService
  def initialize(client: CalendlyClient.new, provider_id:)
    @client = client
    @provider_id = provider_id
  end

  # Syncs availabilities for a provider based on the Calendly feed.
  # Candidates should fetch slots from the CalendlyClient and upsert Availability records.
  def call
    counts = { created: 0, updated: 0, unchanged: 0, total: 0 }
    errors = []

    client.fetch_slots(provider_id).each do |slot|
      counts[:total] += 1

      availability = availability_from_slot(slot)

      new_record = availability.new_record?
      unless new_record || availability.changed?
        counts[:unchanged] += 1
        next
      end

      if availability.save
        new_record ? counts[:created] += 1 : counts[:updated] += 1
      else
        errors << { external_id: slot["id"], messages: availability.errors.full_messages }
      end
    end

    return failure(message: "Some availabilities failed to sync", counts:, errors:) if errors.any?

    success(counts:)
  end

  private

  attr_reader :client, :provider_id

  def availability_from_slot(slot)
    starts = slot["starts_at"]
    ends = slot["ends_at"]

    availability = Availability.find_or_initialize_by(
      provider_id:,
      source: slot["source"],
      external_id: slot["id"]
    )

    availability.assign_attributes(
      start_day_of_week: starts["day_of_week"],
      end_day_of_week: ends["day_of_week"],
      start_time: starts["time"],
      end_time: ends["time"]
    )

    availability
  end
end
