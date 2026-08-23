FactoryBot.define do
  factory :notification do
    tenant
    recipient { association :user, tenant: tenant }
    kind { "mention" }
    message { "You were mentioned." }
  end
end
