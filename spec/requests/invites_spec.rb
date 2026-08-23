require "rails_helper"

RSpec.describe "Invites", type: :request do
  let(:tenant) { create(:tenant, subdomain: "acme") }

  before { host! "#{tenant.subdomain}.example.com" }

  def sign_in_as(user, password: "password123")
    post session_path, params: { email_address: user.email_address, password: password }
  end

  describe "GET /invites" do
    it "renders the index for an owner, including a copyable link for an active invite" do
      Current.tenant = tenant
      owner = create(:user, tenant: tenant, role: "owner")
      active = create(:invite, tenant: tenant, created_by: owner, role: "member")
      used = create(:invite, tenant: tenant, created_by: owner, role: "admin")
      used.redeem!(user: create(:user, tenant: tenant))
      Current.tenant = nil
      sign_in_as(owner)

      get invites_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("member").and include("admin")
      expect(response.body).to include("redeemed")
      expect(response.body).to match(%r{registration/new\?invite_token=\S+})
    end

    it "forbids a member from viewing the index" do
      Current.tenant = tenant
      member = create(:user, tenant: tenant, role: "member")
      Current.tenant = nil
      sign_in_as(member)

      get invites_path

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /invites/new" do
    it "renders the form for an owner" do
      Current.tenant = tenant
      owner = create(:user, tenant: tenant, role: "owner")
      Current.tenant = nil
      sign_in_as(owner)

      get new_invite_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Invite someone")
    end
  end

  describe "POST /invites" do
    it "lets an owner create an invite" do
      Current.tenant = tenant
      owner = create(:user, tenant: tenant, role: "owner")
      Current.tenant = nil
      sign_in_as(owner)

      post invites_path, params: { invite: { role: "member", generation_limit: 3 } }

      expect(response).to redirect_to(invites_path)

      Current.tenant = tenant
      expect(Invite.count).to eq(1)
      Current.tenant = nil
    end

    it "lets an admin create an invite" do
      Current.tenant = tenant
      admin = create(:user, tenant: tenant, role: "admin")
      Current.tenant = nil
      sign_in_as(admin)

      post invites_path, params: { invite: { role: "member", generation_limit: 3 } }

      expect(response).to redirect_to(invites_path)
    end

    it "forbids a member from creating an invite" do
      Current.tenant = tenant
      member = create(:user, tenant: tenant, role: "member")
      Current.tenant = nil
      sign_in_as(member)

      post invites_path, params: { invite: { role: "member", generation_limit: 3 } }

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects an invite role of owner (not a grantable role)" do
      Current.tenant = tenant
      owner = create(:user, tenant: tenant, role: "owner")
      Current.tenant = nil
      sign_in_as(owner)

      post invites_path, params: { invite: { role: "owner", generation_limit: 3 } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /invites/forward" do
    it "mints a next-generation token for a valid, active invite" do
      Current.tenant = tenant
      owner = create(:user, tenant: tenant, role: "owner")
      invite = create(:invite, tenant: tenant, created_by: owner)
      token = invite.token(generation: 0)
      Current.tenant = nil

      post forward_invite_path, params: { token: token }

      expect(response).to have_http_status(:ok)
      forwarded_payload = Invite.decode_token(JSON.parse(response.body)["token"])
      expect(forwarded_payload["generation"]).to eq(1)

      Current.tenant = tenant
      expect(invite.reload.forward_log.size).to eq(1)
      Current.tenant = nil
    end

    it "refuses to forward past the generation limit" do
      Current.tenant = tenant
      owner = create(:user, tenant: tenant, role: "owner")
      invite = create(:invite, tenant: tenant, created_by: owner, generation_limit: 1)
      token = invite.token(generation: 1) # already at the limit
      Current.tenant = nil

      post forward_invite_path, params: { token: token }

      expect(response).to have_http_status(:forbidden)
    end

    it "refuses to forward an already-redeemed invite" do
      Current.tenant = tenant
      owner = create(:user, tenant: tenant, role: "owner")
      invite = create(:invite, tenant: tenant, created_by: owner)
      invite.redeem!(user: create(:user, tenant: tenant))
      token = invite.token(generation: 0)
      Current.tenant = nil

      post forward_invite_path, params: { token: token }

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects a tampered token without ever loading an invite" do
      post forward_invite_path, params: { token: "not-a-real-token" }

      expect(response).to have_http_status(:forbidden)
    end

    it "does not require authentication" do
      Current.tenant = tenant
      owner = create(:user, tenant: tenant, role: "owner")
      invite = create(:invite, tenant: tenant, created_by: owner)
      token = invite.token
      Current.tenant = nil

      post forward_invite_path, params: { token: token }

      expect(response).to have_http_status(:ok)
    end
  end
end
