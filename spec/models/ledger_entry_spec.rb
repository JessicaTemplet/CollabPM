require "rails_helper"

RSpec.describe LedgerEntry do
  let(:tenant) { create(:tenant) }
  let(:creator) { create(:user, tenant: tenant) }

  around do |example|
    Current.tenant = tenant
    example.run
    Current.tenant = nil
  end

  it "requires a subject for a value entry" do
    entry = build(:ledger_entry, tenant: tenant, created_by: creator, entry_type: "value", subject: nil)
    expect(entry).not_to be_valid
  end

  it "allows a nil subject for a payment entry" do
    entry = build(:ledger_entry, tenant: tenant, created_by: creator, entry_type: "payment", subject: nil)
    expect(entry).to be_valid
  end

  it "is append-only — updates are refused" do
    entry = create(:ledger_entry, tenant: tenant, created_by: creator)
    expect { entry.update(amount_cents: 1) }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "rejects an unknown method or entry_type" do
    expect(build(:ledger_entry, tenant: tenant, created_by: creator).tap { |e| e.method = "salary" }).not_to be_valid
    expect(build(:ledger_entry, tenant: tenant, created_by: creator, entry_type: "refund")).not_to be_valid
  end
end
