FactoryBot.define do
  factory :appointment do
    association :client
    association :provider

    starts_at { "2025-10-06 09:00" }
    ends_at { "2025-10-06 10:00" }

    status { :scheduled }
  end
end
