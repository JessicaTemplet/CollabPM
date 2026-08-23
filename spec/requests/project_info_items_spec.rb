require "rails_helper"

RSpec.describe "Project info items", type: :request do
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

  it "creates and lists an item grouped by kind" do
    post project_info_items_path, params: { project_info_item: { kind: "cloud_dependency", name: "Postgres 18" } }
    expect(response).to redirect_to(project_info_items_path)

    get project_info_items_path

    expect(response.body).to include("Postgres 18")
  end

  it "rejects an unknown kind" do
    post project_info_items_path, params: { project_info_item: { kind: "bogus", name: "X" } }

    Current.tenant = tenant
    expect(ProjectInfoItem.count).to eq(0)
    Current.tenant = nil
  end

  it "removes an item" do
    Current.tenant = tenant
    item = create(:project_info_item, tenant: tenant, created_by: owner)
    Current.tenant = nil

    delete project_info_item_path(item)

    expect(response).to redirect_to(project_info_items_path)
    Current.tenant = tenant
    expect(ProjectInfoItem.find_by(id: item.id)).to be_nil
    Current.tenant = nil
  end
end
