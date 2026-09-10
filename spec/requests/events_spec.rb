require "rails_helper"

RSpec.describe "Events", type: :request do
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

  it "creates an event" do
    start_at = 1.day.from_now
    post events_path, params: {
      event: { title: "Standup", start_at: start_at, end_at: start_at + 30.minutes }
    }

    # Redirects to the month the new event actually falls in, not always the
    # current month — matters once you add something for next month and
    # don't want it to vanish the moment you're sent back to today.
    expect(response).to redirect_to(events_path(month: start_at.to_date.strftime("%Y-%m")))
    Current.tenant = tenant
    expect(Event.find_by(title: "Standup")).to be_present
    Current.tenant = nil
  end

  it "shows this month's events and proposals due this month on the index" do
    Current.tenant = tenant
    create(:event, tenant: tenant, created_by: owner, title: "Kickoff",
      start_at: Date.current.beginning_of_month.to_time + 1.day, end_at: Date.current.beginning_of_month.to_time + 1.day + 1.hour)
    proposal = create(:proposal, tenant: tenant, created_by: owner, title: "Ship the thing", due_date: Date.current)
    Current.tenant = nil

    get events_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Kickoff")
    expect(response.body).to include(proposal.title)
  end

  it "destroys an event" do
    Current.tenant = tenant
    event = create(:event, tenant: tenant, created_by: owner)
    Current.tenant = nil

    delete event_path(event)

    expect(response).to redirect_to(events_path(month: event.start_at.to_date.strftime("%Y-%m")))
    Current.tenant = tenant
    expect(Event.find_by(id: event.id)).to be_nil
    Current.tenant = nil
  end

  it "navigates to a different month and only shows that month's events" do
    Current.tenant = tenant
    next_month_date = (Date.current.beginning_of_month + 1.month) + 1.day
    create(:event, tenant: tenant, created_by: owner, title: "Future Kickoff",
      start_at: next_month_date.to_time.change(hour: 10), end_at: next_month_date.to_time.change(hour: 11))
    create(:event, tenant: tenant, created_by: owner, title: "This Month Standup",
      start_at: Date.current.beginning_of_month.to_time + 1.day, end_at: Date.current.beginning_of_month.to_time + 1.day + 1.hour)
    Current.tenant = nil

    get events_path(month: next_month_date.strftime("%Y-%m"))

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Future Kickoff")
    expect(response.body).not_to include("This Month Standup")
  end
end
