FactoryBot.define do
  factory :outreach_contact do
    tenant
    created_by { association :user, tenant: tenant }
    sequence(:name) { |n| "Contact #{n}" }
    channel { "email" }
    status { "planned" }
    kind { "grassroots" }
  end
end
