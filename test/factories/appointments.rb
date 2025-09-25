FactoryBot.define do
  factory :appointment do
    association :client
    association :provider

    transient do
      base_day { Time.zone.now.next_week(:monday) }
    end

    starts_at { base_day.change(hour: 9, min: 0) }
    ends_at { base_day.change(hour: 10, min: 0) }

    status { :scheduled }
  end
end
