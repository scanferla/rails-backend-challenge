json.id @appointment.id
json.client_id @appointment.client_id
json.provider_id @appointment.provider_id
json.status @appointment.status
json.starts_at @appointment.starts_at.iso8601
json.ends_at @appointment.ends_at.iso8601
json.created_at @appointment.created_at.iso8601
json.updated_at @appointment.updated_at.iso8601
