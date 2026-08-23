require "rails_helper"

RSpec.describe "Ledger entries", type: :request do
  let(:tenant) { create(:tenant, subdomain: "acme") }
  let(:owner) do
    Current.tenant = tenant
    create(:user, tenant: tenant, email_address: "owner@acme.test",
                  password: "password123", password_confirmation: "password123")
  end

  before do
    owner
    Current.tenant = nil
    host! "#{tenant.subdomain}.example.com"
    post session_path, params: { email_address: "owner@acme.test", password: "password123" }
  end

  it "records a value entry against a proposal" do
    Current.tenant = tenant
    proposal = create(:proposal, tenant: tenant, created_by: owner)
    Current.tenant = nil

    post ledger_entries_path, params: {
      ledger_entry: { method: "hourly", entry_type: "value", amount_cents: 5000, subject_type: "Proposal", subject_id: proposal.id }
    }

    expect(response).to redirect_to(ledger_entries_path)
    Current.tenant = tenant
    expect(LedgerEntry.count).to eq(1)
    Current.tenant = nil
  end

  it "shows the outstanding balance as value entries minus payments" do
    Current.tenant = tenant
    proposal = create(:proposal, tenant: tenant, created_by: owner)
    create(:ledger_entry, tenant: tenant, created_by: owner, entry_type: "value", amount_cents: 10_000, subject: proposal)
    create(:ledger_entry, tenant: tenant, created_by: owner, entry_type: "payment", amount_cents: 4_000, subject: nil)
    Current.tenant = nil

    get ledger_entries_path

    expect(response.body).to include("60.00")
  end
end
