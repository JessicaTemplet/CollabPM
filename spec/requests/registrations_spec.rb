require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:tenant) { create(:tenant, subdomain: "acme") }

  before { host! "#{tenant.subdomain}.example.com" }

  def create_owner
    Current.tenant = tenant
    owner = create(:user, tenant: tenant, role: "owner")
    Current.tenant = nil
    owner
  end

  describe "bootstrap (first user for a tenant)" do
    it "makes the first user for a tenant the owner, with no invite token required" do
      post registration_path, params: {
        user: { email_address: "first@example.test", password: "password123", password_confirmation: "password123" }
      }

      Current.tenant = tenant
      expect(User.find_by!(email_address: "first@example.test").role).to eq("owner")
    end

    it "starts a new tenant's owner count independently of other tenants" do
      other_tenant = create(:tenant, subdomain: "beta")
      Current.tenant = other_tenant
      create(:user, tenant: other_tenant, role: "owner")
      Current.tenant = nil

      # `tenant` (acme) still has zero users even though `beta` already has
      # an owner — this registration should still bootstrap as owner.
      post registration_path, params: {
        user: { email_address: "first@example.test", password: "password123", password_confirmation: "password123" }
      }

      Current.tenant = tenant
      expect(User.find_by!(email_address: "first@example.test").role).to eq("owner")
    end
  end

  describe "GET /registration/new" do
    it "renders the signup form given a valid invite token" do
      owner = create_owner
      Current.tenant = tenant
      invite = create(:invite, tenant: tenant, created_by: owner)
      token = invite.token
      Current.tenant = nil

      get new_registration_path, params: { invite_token: token }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create your account")
    end

    it "rejects an invalid invite token before rendering the form" do
      create_owner

      get new_registration_path, params: { invite_token: "garbage" }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "every registration after the first" do
    it "rejects registration with no invite token at all" do
      create_owner

      post registration_path, params: {
        user: { email_address: "second@example.test", password: "password123", password_confirmation: "password123" }
      }

      expect(response).to have_http_status(:forbidden)
      Current.tenant = tenant
      expect(User.exists?(email_address: "second@example.test")).to be false
    end

    it "rejects a tampered invite token" do
      create_owner

      post registration_path, params: {
        invite_token: "garbage",
        user: { email_address: "second@example.test", password: "password123", password_confirmation: "password123" }
      }

      expect(response).to have_http_status(:forbidden)
    end

    it "grants the invite's role and marks the invite redeemed, given a valid token" do
      owner = create_owner
      Current.tenant = tenant
      invite = create(:invite, tenant: tenant, created_by: owner, role: "admin")
      token = invite.token
      Current.tenant = nil

      post registration_path, params: {
        invite_token: token,
        user: { email_address: "second@example.test", password: "password123", password_confirmation: "password123" }
      }

      expect(response).to redirect_to(tenant_root_path)
      Current.tenant = tenant
      expect(User.find_by!(email_address: "second@example.test").role).to eq("admin")
      expect(invite.reload.used_at).to be_present
      expect(invite.used_by.email_address).to eq("second@example.test")
    end

    it "accepts a token forwarded to a later generation" do
      owner = create_owner
      Current.tenant = tenant
      invite = create(:invite, tenant: tenant, created_by: owner, role: "member")
      forwarded_token = invite.token(generation: 1)
      Current.tenant = nil

      post registration_path, params: {
        invite_token: forwarded_token,
        user: { email_address: "third@example.test", password: "password123", password_confirmation: "password123" }
      }

      expect(response).to redirect_to(tenant_root_path)
    end

    it "rejects a token already redeemed, even a different forwarded copy of it" do
      owner = create_owner
      Current.tenant = tenant
      invite = create(:invite, tenant: tenant, created_by: owner)
      root_token = invite.token(generation: 0)
      forwarded_token = invite.token(generation: 1)
      Current.tenant = nil

      post registration_path, params: {
        invite_token: root_token,
        user: { email_address: "first_redeemer@example.test", password: "password123", password_confirmation: "password123" }
      }
      expect(response).to redirect_to(tenant_root_path)

      post registration_path, params: {
        invite_token: forwarded_token,
        user: { email_address: "second_redeemer@example.test", password: "password123", password_confirmation: "password123" }
      }
      expect(response).to have_http_status(:forbidden)
    end

    it "rejects a token past its generation limit" do
      owner = create_owner
      Current.tenant = tenant
      invite = create(:invite, tenant: tenant, created_by: owner, generation_limit: 2)
      over_limit_token = invite.token(generation: 3)
      Current.tenant = nil

      post registration_path, params: {
        invite_token: over_limit_token,
        user: { email_address: "second@example.test", password: "password123", password_confirmation: "password123" }
      }

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects an expired invite's token" do
      owner = create_owner
      Current.tenant = tenant
      invite = create(:invite, tenant: tenant, created_by: owner, expires_at: 1.minute.from_now)
      token = invite.token
      Current.tenant = nil

      travel_to 2.minutes.from_now do
        post registration_path, params: {
          invite_token: token,
          user: { email_address: "second@example.test", password: "password123", password_confirmation: "password123" }
        }
      end

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects an invite token minted for a different tenant" do
      create_owner
      other_tenant = create(:tenant, subdomain: "beta")
      Current.tenant = other_tenant
      other_owner = create(:user, tenant: other_tenant, role: "owner")
      foreign_invite = create(:invite, tenant: other_tenant, created_by: other_owner)
      foreign_token = foreign_invite.token
      Current.tenant = nil

      post registration_path, params: {
        invite_token: foreign_token,
        user: { email_address: "second@example.test", password: "password123", password_confirmation: "password123" }
      }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
