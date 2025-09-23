json.provider_id @provider.id
json.from @availability_params.from.iso8601
json.to @availability_params.to.iso8601

json.free_slots @free_slots do |slot|
  json.starts_at slot[:starts_at].iso8601
  json.ends_at slot[:ends_at].iso8601
end
