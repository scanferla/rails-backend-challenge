class AvailabilitySync
  def initialize(client: CalendlyClient.new)
    @client = client
  end

  # Syncs availabilities for a provider based on the Calendly feed.
  # Candidates should fetch slots from the CalendlyClient and upsert Availability records.
  def call(provider_id:)
    raise NotImplementedError, "Implement availability sync logic"
  end

  private

  attr_reader :client
end
