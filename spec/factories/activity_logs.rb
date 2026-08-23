FactoryBot.define do
  factory :activity_log do
    tenant
    actor { association :user, tenant: tenant }
    action { "created" }
    payload { {} }
  end
end
