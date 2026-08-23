require "rails_helper"

RSpec.describe Event do
  let(:tenant) { create(:tenant) }
  let(:creator) { create(:user, tenant: tenant) }

  around do |example|
    Current.tenant = tenant
    example.run
    Current.tenant = nil
  end

  it "requires title, start_at, and end_at" do
    expect(build(:event, tenant: tenant, created_by: creator, title: nil)).not_to be_valid
  end

  it "rejects an end time before the start time" do
    event = build(:event, tenant: tenant, created_by: creator,
      start_at: Time.zone.parse("2026-01-01 10:00"), end_at: Time.zone.parse("2026-01-01 09:00"))

    expect(event).not_to be_valid
  end

  it "allows an end time equal to the start time" do
    same = Time.zone.parse("2026-01-01 10:00")
    event = build(:event, tenant: tenant, created_by: creator, start_at: same, end_at: same)

    expect(event).to be_valid
  end
end
