class InvitesController < ApplicationController
  before_action :require_admin!

  def index
    @invites = Current.tenant.invites.order(created_at: :desc)
  end

  def new
    @invite = Invite.new
  end

  def create
    @invite = Current.tenant.invites.new(invite_params)
    @invite.role = requested_role
    @invite.created_by = Current.user
    @invite.expires_at = params.dig(:invite, :expires_at).presence || 7.days.from_now

    if @invite.save
      redirect_to invites_path, notice: "Invite link created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  # Only owner/admin can mint invites — this is the door Phase 1 exists to
  # lock, so members shouldn't be able to open it back up for anyone else.
  def require_admin!
    head :forbidden unless Current.user&.role.in?(%w[owner admin])
  end

  def invite_params
    params.require(:invite).permit(:generation_limit)
  end

  # role is deliberately kept out of mass assignment and checked against
  # the model's own allow-list here, so an unrecognized or forged value
  # never reaches the record at all, instead of only failing validation
  # after the fact. Invite still enforces GRANTABLE_ROLES independently —
  # this is defense in depth, not a replacement for it.
  def requested_role
    role = params.dig(:invite, :role)
    role if Invite::GRANTABLE_ROLES.include?(role)
  end
end
