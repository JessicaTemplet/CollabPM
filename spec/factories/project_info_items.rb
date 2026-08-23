FactoryBot.define do
  factory :project_info_item do
    tenant
    created_by { association :user, tenant: tenant }
    kind { "subscription" }
    sequence(:name) { |n| "Service #{n}" }
    details { {} }
  end
end
