require "rails_helper"

RSpec.describe "Outreach contacts", type: :request do
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

  it "creates a grassroots contact" do
    post outreach_contacts_path, params: { outreach_contact: { name: "Jamie", channel: "Twitter", kind: "grassroots" } }

    expect(response).to redirect_to(outreach_contacts_path)
    Current.tenant = tenant
    expect(OutreachContact.find_by(name: "Jamie")).to be_present
    Current.tenant = nil
  end

  it "creates a paid contact with budget and campaign fields" do
    post outreach_contacts_path, params: {
      outreach_contact: { name: "Agency", channel: "Google Ads", kind: "paid", budget_cents: 50_000, campaign_name: "Launch" }
    }

    Current.tenant = tenant
    contact = OutreachContact.find_by!(name: "Agency")
    expect(contact.budget_cents).to eq(50_000)
    expect(contact.campaign_name).to eq("Launch")
    Current.tenant = nil
  end

  it "updates status" do
    Current.tenant = tenant
    contact = create(:outreach_contact, tenant: tenant, created_by: owner)
    Current.tenant = nil

    patch outreach_contact_path(contact), params: { outreach_contact: { status: "contacted" } }

    Current.tenant = tenant
    expect(contact.reload.status).to eq("contacted")
    Current.tenant = nil
  end
end
