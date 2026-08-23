FactoryBot.define do
  factory :event do
    tenant
    created_by { association :user, tenant: tenant }
    sequence(:title) { |n| "Event #{n}" }
    start_at { 1.day.from_now.change(hour: 10) }
    end_at { 1.day.from_now.change(hour: 11) }
  end
end
