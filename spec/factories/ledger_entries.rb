FactoryBot.define do
  factory :ledger_entry do
    tenant
    created_by { association :user, tenant: tenant }
    add_attribute(:method) { "hourly" } # `method` collides with Kernel#method — FactoryBot's DSL needs the explicit form
    entry_type { "value" }
    amount_cents { 10_000 }
    subject { association :proposal, tenant: tenant, created_by: created_by }
  end
end
