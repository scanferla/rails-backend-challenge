# Note:
# We intentionally do not seed Availability or Appointment here.
# - Availability is synchronized from Calendly's fixture via AvailabilitySync.
# - Appointments are created via the POST /appointments endpoint.
# Seed only core entities that lack external sync/endpoints (e.g., Provider, Client).

3.times { |n| Provider.find_or_create_by!(id: n + 1) }
5.times { |n| Client.find_or_create_by!(id: n + 1) }
