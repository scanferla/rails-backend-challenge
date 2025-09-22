FactoryBot.define do
  factory :availability do
    association :provider

    source { "calendly" }
    sequence(:external_id) { |n| "ext-#{n}" }

    start_day_of_week { :monday }
    start_time { "09:00" }

    end_day_of_week { :monday }
    end_time { "11:30" }
  end
end
