FactoryBot.define do
  factory :proposal do
    tenant
    created_by { association :user, tenant: tenant }
    sequence(:title) { |n| "Proposal #{n}" }
    status { "proposed" }
  end
end
