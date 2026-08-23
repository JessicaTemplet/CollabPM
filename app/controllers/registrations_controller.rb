class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  class InvalidInviteError < StandardError; end

  before_action :resolve_invite, only: %i[new create], unless: :bootstrap?

  def new
    @user = User.new
  end

  def create
    # Captured once, up front: `bootstrap?` reflects whether the tenant has
    # zero users, which flips to false the instant @user.save below succeeds
    # — re-checking it afterward would wrongly treat this same registration
    # as "not bootstrapping" by the time we get to the redeem step.
    bootstrapping = bootstrap?

    @user = User.new(user_params)
    @user.role = bootstrapping ? "owner" : @invite.role

    if @user.save
      @invite.redeem!(user: @user) unless bootstrapping
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "Welcome!"
    else
      render :new, status: :unprocessable_entity
    end
  rescue Invite::AlreadyUsedError
    render_invalid_invite
  end

  private

  # The one open door left on purpose: a brand-new tenant has nobody in it
  # yet to have sent an invite, so the very first registration bootstraps
  # the owner. Every registration after that must carry a valid invite token.
  def bootstrap?
    !Current.tenant.users.exists?
  end

  def resolve_invite
    payload = Invite.decode_token(params[:invite_token])
    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    # Scoped to Current.tenant, then re-verified against invite.tenant_id
    # below — the token's embedded tenant_id is a hint, never authoritative.
    invite = Current.tenant.invites.find(payload["invite_id"])
    generation = payload["generation"].to_i

    raise InvalidInviteError unless invite.tenant_id == Current.tenant.id && invite.usable_at_generation?(generation)

    @invite = invite
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound, InvalidInviteError
    render_invalid_invite
  end

  def render_invalid_invite
    render plain: "This invite link is invalid or has expired.", status: :forbidden
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
