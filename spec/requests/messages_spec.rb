require "rails_helper"

RSpec.describe "Team feed", type: :request do
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

  it "posts a message to the tenant-wide feed and lists it" do
    post messages_path, params: { comment: { body: "Shipped the invite flow" } }
    expect(response).to redirect_to(messages_path)

    get messages_path

    expect(response.body).to include("Shipped the invite flow")
    expect(response.body).to include(owner.email_address)
  end

  it "does not leak another tenant's messages into this feed" do
    other_tenant = create(:tenant, subdomain: "beta")
    Current.tenant = other_tenant
    other_owner = create(:user, tenant: other_tenant)
    other_tenant.comments.create!(author: other_owner, body: "Beta-only update")
    Current.tenant = nil

    get messages_path

    expect(response.body).not_to include("Beta-only update")
  end
end
