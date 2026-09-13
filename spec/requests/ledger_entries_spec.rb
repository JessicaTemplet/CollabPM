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

  it "records a value entry with a deliverable description" do
    post ledger_entries_path, params: {
      ledger_entry: { method: "hourly", entry_type: "value", amount_cents: 5000, description: "Homepage redesign" }
    }

    expect(response).to redirect_to(ledger_entries_path)
    Current.tenant = tenant
    expect(LedgerEntry.count).to eq(1)
    Current.tenant = nil
  end

  it "rejects a value entry with no description" do
    post ledger_entries_path, params: {
      ledger_entry: { method: "hourly", entry_type: "value", amount_cents: 5000, description: "" }
    }

    expect(response).to redirect_to(ledger_entries_path)
    follow_redirect!
    expect(response.body).to include("is required for a value entry")
    Current.tenant = tenant
    expect(LedgerEntry.count).to eq(0)
    Current.tenant = nil
  end

  it "shows the outstanding balance as value entries minus payments" do
    Current.tenant = tenant
    create(:ledger_entry, tenant: tenant, created_by: owner, entry_type: "value", amount_cents: 10_000, description: "Phase one")
    create(:ledger_entry, tenant: tenant, created_by: owner, entry_type: "payment", amount_cents: 4_000, description: nil)
    Current.tenant = nil

    get ledger_entries_path

    expect(response.body).to include("60.00")
  end

  it "prints a single entry as an invoice-style page" do
    Current.tenant = tenant
    entry = create(:ledger_entry, tenant: tenant, created_by: owner, entry_type: "value", amount_cents: 12_000, description: "Homepage redesign")
    Current.tenant = nil

    get ledger_entry_path(entry)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Homepage redesign")
    expect(response.body).to include("120.00")
  end

  it "404s printing another tenant's entry" do
    other_tenant = create(:tenant, subdomain: "other")
    Current.tenant = other_tenant
    other_owner = create(:user, tenant: other_tenant)
    entry = create(:ledger_entry, tenant: other_tenant, created_by: other_owner)
    Current.tenant = nil

    get ledger_entry_path(entry)

    expect(response).to have_http_status(:not_found)
  end
end
