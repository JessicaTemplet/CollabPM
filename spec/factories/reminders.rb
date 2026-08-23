FactoryBot.define do
  factory :reminder do
    tenant
    created_by { association :user, tenant: tenant }
    remind_at { 1.hour.from_now }
    message { "Follow up" }
    status { "pending" }
  end
end
