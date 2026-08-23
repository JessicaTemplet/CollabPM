require "rails_helper"

RSpec.describe "Reminders", type: :request do
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

  it "creates a reminder owned by the current user" do
    post reminders_path, params: { reminder: { remind_at: 1.day.from_now, message: "Ping Sheenita" } }

    expect(response).to redirect_to(reminders_path)
    Current.tenant = tenant
    reminder = Reminder.find_by!(message: "Ping Sheenita")
    expect(reminder.created_by).to eq(owner)
    expect(reminder.status).to eq("pending")
    Current.tenant = nil
  end
end
