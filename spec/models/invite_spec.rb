require "rails_helper"

RSpec.describe Invite do
  let(:tenant) { create(:tenant) }
  let(:owner) { Current.tenant = tenant; create(:user, tenant: tenant, role: "owner") }

  around do |example|
    Current.tenant = tenant
    example.run
    Current.tenant = nil
  end

  def build_invite(**attrs)
    create(:invite, tenant: tenant, created_by: owner, **attrs)
  end

  describe "#token / .decode_token" do
    it "round-trips invite_id, tenant_id, and generation" do
      invite = build_invite
      payload = Invite.decode_token(invite.token(generation: 2))

      expect(payload).to eq("invite_id" => invite.id, "tenant_id" => tenant.id, "generation" => 2)
    end

    it "rejects a tampered token without touching the database" do
      invite = build_invite
      token = invite.token
      tampered = token.chop + (token[-1] == "a" ? "b" : "a")

      expect { Invite.decode_token(tampered) }.to raise_error(ActiveSupport::MessageVerifier::InvalidSignature)
    end

    it "rejects a token once its invite has expired" do
      invite = build_invite(expires_at: 1.minute.from_now)
      token = invite.token

      travel_to 2.minutes.from_now do
        expect { Invite.decode_token(token) }.to raise_error(ActiveSupport::MessageVerifier::InvalidSignature)
      end
    end

    it "cannot be decoded by a differently-purposed verifier (namespace isolation)" do
      invite = build_invite
      token = invite.token

      expect {
        Rails.application.message_verifier(:something_else).verify(token)
      }.to raise_error(ActiveSupport::MessageVerifier::InvalidSignature)
    end
  end

  describe "#usable_at_generation?" do
    it "is true for a fresh invite at generation 0" do
      expect(build_invite).to be_usable_at_generation(0)
    end

    it "is false once used" do
      invite = build_invite
      Current.tenant = tenant
      invite.redeem!(user: create(:user, tenant: tenant))

      expect(invite).not_to be_usable_at_generation(0)
    end

    it "is false once expired" do
      invite = build_invite(expires_at: 1.minute.ago)
      expect(invite).not_to be_usable_at_generation(0)
    end

    it "is false past the generation limit" do
      invite = build_invite(generation_limit: 2)
      expect(invite).to be_usable_at_generation(2)
      expect(invite).not_to be_usable_at_generation(3)
    end
  end

  describe "#redeem!" do
    it "sets used_at and used_by exactly once" do
      invite = build_invite
      user = create(:user, tenant: tenant)

      invite.redeem!(user: user)

      expect(invite.used_at).to be_present
      expect(invite.used_by).to eq(user)
    end

    it "raises AlreadyUsedError on a second redemption attempt" do
      invite = build_invite
      invite.redeem!(user: create(:user, tenant: tenant))

      expect {
        invite.redeem!(user: create(:user, tenant: tenant))
      }.to raise_error(Invite::AlreadyUsedError)
    end
  end

  describe "#record_forward!" do
    it "appends to forward_log without touching used_at or role" do
      invite = build_invite
      invite.record_forward!(generation: 1)

      expect(invite.forward_log.size).to eq(1)
      expect(invite.forward_log.first["generation"]).to eq(1)
      expect(invite.used_at).to be_nil
    end
  end
end
