require "rails_helper"

RSpec.describe "Proposals", type: :request do
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

  it "creates a proposal owned by the current user" do
    post proposals_path, params: { proposal: { title: "Add dark mode" } }

    Current.tenant = tenant
    proposal = Proposal.find_by!(title: "Add dark mode")
    expect(proposal.created_by).to eq(owner)
    expect(proposal.status).to eq("proposed")
    Current.tenant = nil

    expect(response).to redirect_to(proposal_path(proposal))
  end

  it "updates status and assignee" do
    Current.tenant = tenant
    proposal = create(:proposal, tenant: tenant, created_by: owner)
    Current.tenant = nil

    patch proposal_path(proposal), params: { proposal: { status: "approved", assignee_id: owner.id } }

    Current.tenant = tenant
    proposal.reload
    expect(proposal.status).to eq("approved")
    expect(proposal.assignee).to eq(owner)
    Current.tenant = nil
  end

  it "groups the index by status for the kanban board" do
    Current.tenant = tenant
    create(:proposal, tenant: tenant, created_by: owner, title: "In progress one", status: "in_progress")
    create(:proposal, tenant: tenant, created_by: owner, title: "Still proposed")
    Current.tenant = nil

    get proposals_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("In progress one").and include("Still proposed")
  end

  it "filters the index to the current user's assigned proposals with ?mine=1" do
    Current.tenant = tenant
    mine = create(:proposal, tenant: tenant, created_by: owner, assignee: owner, title: "Mine")
    other_user = create(:user, tenant: tenant)
    create(:proposal, tenant: tenant, created_by: owner, assignee: other_user, title: "Not mine")
    Current.tenant = nil

    get proposals_path(mine: 1)

    expect(response.body).to include(mine.title)
    expect(response.body).not_to include("Not mine")
  end

  it "404s for a proposal belonging to a different tenant" do
    other_tenant = create(:tenant, subdomain: "beta")
    Current.tenant = other_tenant
    other_owner = create(:user, tenant: other_tenant)
    other_proposal = create(:proposal, tenant: other_tenant, created_by: other_owner)
    Current.tenant = nil

    get proposal_path(other_proposal)

    expect(response).to have_http_status(:not_found)
  end
end
