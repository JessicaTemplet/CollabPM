class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  # Public demo account, prefilled on the login page. Created on first use
  # so the live database doesn't need a reseed.
  GUEST_EMAIL = "guest@acme.test".freeze
  GUEST_PASSWORD = "guestdemo".freeze

  def new
  end

  def create
    ensure_guest_user if params[:email_address].to_s.strip.downcase == GUEST_EMAIL && params[:password] == GUEST_PASSWORD

    # `User` is already scoped to Current.tenant via TenantScoped, so this
    # can never authenticate a user from a different tenant even if two
    # tenants share the same email address.
    if (user = User.find_by(email_address: params[:email_address])) && user.authenticate(params[:password])
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Invalid email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private

  def ensure_guest_user
    return unless Current.tenant

    User.find_or_create_by!(email_address: GUEST_EMAIL) do |u|
      u.password = GUEST_PASSWORD
      u.password_confirmation = GUEST_PASSWORD
      u.role = "member"
    end
  end
end
