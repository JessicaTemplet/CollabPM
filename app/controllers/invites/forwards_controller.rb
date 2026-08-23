module Invites
  # Lets someone holding a valid, not-yet-redeemed invite token mint a new
  # token for the next hop (A -> B -> C -> ...) WITHOUT being authenticated —
  # the whole point is that B hasn't registered yet when they forward to C.
  #
  # Because the forwarder isn't a User, the new token can't claim "forwarded
  # by B" the way an authenticated action could; see Invite#record_forward!
  # for what gets logged instead.
  class ForwardsController < ApplicationController
    allow_unauthenticated_access only: :create
    rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render plain: "Try again later.", status: :too_many_requests }

    def create
      payload = Invite.decode_token(params[:token])
      # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
      # Scoped to Current.tenant, then re-verified against invite.tenant_id
      # below — the token's embedded tenant_id is a hint, never authoritative.
      invite = Current.tenant.invites.find(payload["invite_id"])
      next_generation = payload["generation"].to_i + 1

      # tenant_id is re-checked against the loaded row on purpose — the
      # embedded value in the token is a fast-path hint, never authoritative.
      if invite.tenant_id != Current.tenant.id || !invite.usable_at_generation?(next_generation)
        return render plain: "This invite can no longer be forwarded.", status: :forbidden
      end

      invite.record_forward!(generation: next_generation)
      render json: { token: invite.token(generation: next_generation) }
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
      render plain: "This invite link is invalid or has expired.", status: :forbidden
    end
  end
end
