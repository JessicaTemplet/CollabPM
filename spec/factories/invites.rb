FactoryBot.define do
  factory :invite do
    tenant
    created_by { association :user, tenant: tenant, role: "owner" }
    role              { "member" }
    generation_limit  { 3 }
    expires_at        { 7.days.from_now }
  end
end
