require "rails_helper"

RSpec.describe "Documents index and folders", type: :request do
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

  it "lists root-level folders and documents" do
    Current.tenant = tenant
    folder = create(:folder, tenant: tenant, name: "Specs")
    document = create(:document, tenant: tenant, title: "Root doc")
    create(:document, tenant: tenant, title: "Nested doc", folder: folder)
    Current.tenant = nil

    get documents_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Specs").and include("Root doc")
    expect(response.body).not_to include("Nested doc")
  end

  it "lists only a folder's own contents when scoped to it" do
    Current.tenant = tenant
    folder = create(:folder, tenant: tenant, name: "Specs")
    nested = create(:document, tenant: tenant, title: "Nested doc", folder: folder)
    Current.tenant = nil

    get documents_path(folder_id: folder.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(nested.title)
  end

  it "creates a folder" do
    post folders_path, params: { folder: { name: "New folder" } }

    expect(response).to redirect_to(documents_path(folder_id: nil))
    Current.tenant = tenant
    expect(Folder.find_by(name: "New folder")).to be_present
    Current.tenant = nil
  end

  it "creates a document inside a folder" do
    Current.tenant = tenant
    folder = create(:folder, tenant: tenant)
    Current.tenant = nil

    post documents_path, params: { document: { title: "Notes", folder_id: folder.id } }

    Current.tenant = tenant
    expect(response).to redirect_to(document_path(Document.find_by!(title: "Notes")))
    Current.tenant = nil
  end
end
