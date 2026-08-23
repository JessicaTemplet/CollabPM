require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:tenant) { create(:tenant, subdomain: "acme") }

  before { host! "#{tenant.subdomain}.example.com" }

  def sign_in_as(user, password: "password123")
    post session_path, params: { email_address: user.email_address, password: password }
  end

  it "shows an owner a link to invites" do
    Current.tenant = tenant
    owner = create(:user, tenant: tenant, role: "owner")
    Current.tenant = nil
    sign_in_as(owner)

    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(invites_path)
  end

  it "shows an admin a link to invites" do
    Current.tenant = tenant
    admin = create(:user, tenant: tenant, role: "admin")
    Current.tenant = nil
    sign_in_as(admin)

    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(invites_path)
  end

  it "does not show a member a link to invites" do
    Current.tenant = tenant
    member = create(:user, tenant: tenant, role: "member")
    Current.tenant = nil
    sign_in_as(member)

    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(invites_path)
  end
end
