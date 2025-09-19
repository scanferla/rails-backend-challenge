require "json"

class CalendlyClient
  FIXTURE_PATH = Rails.root.join("test", "fixtures", "files", "calendly_slots.json").freeze

  def fetch_slots(provider_id)
    JSON.parse(File.read(FIXTURE_PATH)).fetch(provider_id.to_s, [])
  rescue Errno::ENOENT
    raise "Calendly fixture missing at #{FIXTURE_PATH}"
  end
end
