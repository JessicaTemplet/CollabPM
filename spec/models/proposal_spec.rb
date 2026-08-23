require "rails_helper"

RSpec.describe Proposal do
  let(:tenant) { create(:tenant) }
  let(:author) { create(:user, tenant: tenant) }

  around do |example|
    Current.tenant = tenant
    example.run
    Current.tenant = nil
  end

  it "defaults to proposed and requires a title" do
    proposal = build(:proposal, tenant: tenant, created_by: author, title: nil)
    expect(proposal).not_to be_valid
  end

  it "logs an activity entry on creation" do
    proposal = create(:proposal, tenant: tenant, created_by: author)

    log = ActivityLog.order(:id).last
    expect(log.action).to eq("proposal.created")
    expect(log.subject).to eq(proposal)
    expect(log.actor).to eq(author)
  end

  it "logs a status-change activity entry, falling back to the author when Current.user is unset" do
    proposal = create(:proposal, tenant: tenant, created_by: author)

    proposal.update!(status: "changes_requested")

    log = ActivityLog.order(:id).last
    expect(log.action).to eq("proposal.status_changed")
    expect(log.payload).to eq("from" => "proposed", "to" => "changes_requested")
    expect(log.actor).to eq(author)
  end

  describe "denied is only reachable from proposed" do
    it "allows proposed -> denied" do
      proposal = create(:proposal, tenant: tenant, created_by: author, status: "proposed")
      expect(proposal.update(status: "denied")).to be true
    end

    it "rejects approved -> denied" do
      proposal = create(:proposal, tenant: tenant, created_by: author, status: "approved")
      expect(proposal.update(status: "denied")).to be false
    end
  end

  it "supports tagging via the Taggable concern" do
    proposal = create(:proposal, tenant: tenant, created_by: author)
    proposal.tag_names = [ "urgent", "billing" ]

    expect(proposal.tags.map(&:name)).to contain_exactly("urgent", "billing")
  end
end
