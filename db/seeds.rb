provider1 = Provider.find_or_create_by!(id: 1)
provider2 = Provider.find_or_create_by!(id: 2)

client1 = Client.find_or_create_by!(id: 1)
client2 = Client.find_or_create_by!(id: 2)

Availability.find_or_create_by!(provider: provider1, source: "calendly", external_id: "p1-slot-early-morning") do |a|
  a.start_day_of_week = :monday
  a.start_time = "08:00"
  a.end_day_of_week = :monday
  a.end_time = "09:30"
end

Availability.find_or_create_by!(provider: provider2, source: "calendly", external_id: "p2-slot-short") do |a|
  a.start_day_of_week = :tuesday
  a.start_time = "14:00"
  a.end_day_of_week = :tuesday
  a.end_time = "15:30"
end

Appointment.find_or_create_by!(
  client: client1,
  provider: provider1,
  starts_at: "2025-09-29 09:00",
  ends_at: "2025-09-29 09:30",
  status: :scheduled
)

Appointment.find_or_create_by!(
  client: client2,
  provider: provider2,
  starts_at: "2025-09-30 14:15",
  ends_at: "2025-09-30 14:45",
  status: :scheduled
)
