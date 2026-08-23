FactoryBot.define do
  factory :comment do
    tenant
    author { association :user, tenant: tenant }
    commentable { tenant }
    body { "A comment." }
  end
end
