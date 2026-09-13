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

  it "renames a folder" do
    Current.tenant = tenant
    folder = create(:folder, tenant: tenant, name: "Old name")
    Current.tenant = nil

    patch folder_path(folder), params: { folder: { name: "New name" } }

    expect(response).to redirect_to(documents_path(folder_id: nil))
    Current.tenant = tenant
    expect(folder.reload.name).to eq("New name")
    Current.tenant = nil
  end

  it "deletes a folder, nullifying documents directly inside it" do
    Current.tenant = tenant
    folder = create(:folder, tenant: tenant)
    document = create(:document, tenant: tenant, folder: folder)
    Current.tenant = nil

    delete folder_path(folder)

    expect(response).to redirect_to(documents_path(folder_id: nil))
    Current.tenant = tenant
    expect(Folder.find_by(id: folder.id)).to be_nil
    expect(document.reload.folder_id).to be_nil
    Current.tenant = nil
  end

  it "404s renaming another tenant's folder" do
    other_tenant = create(:tenant, subdomain: "beta")
    Current.tenant = other_tenant
    foreign_folder = create(:folder, tenant: other_tenant)
    Current.tenant = nil

    patch folder_path(foreign_folder), params: { folder: { name: "Hijacked" } }

    expect(response).to have_http_status(:not_found)
  end

  it "404s deleting another tenant's folder" do
    other_tenant = create(:tenant, subdomain: "beta")
    Current.tenant = other_tenant
    foreign_folder = create(:folder, tenant: other_tenant)
    Current.tenant = nil

    delete folder_path(foreign_folder)

    expect(response).to have_http_status(:not_found)
  end

  it "renames a document from the index" do
    Current.tenant = tenant
    document = create(:document, tenant: tenant, title: "Old title")
    Current.tenant = nil

    patch document_path(document), params: { document: { title: "New title" } }

    expect(response).to redirect_to(document_path(document))
    Current.tenant = tenant
    expect(document.reload.title).to eq("New title")
    Current.tenant = nil
  end

  it "deletes a document from the index" do
    Current.tenant = tenant
    document = create(:document, tenant: tenant)
    Current.tenant = nil

    delete document_path(document)

    expect(response).to redirect_to(documents_path(folder_id: nil))
    Current.tenant = tenant
    expect(Document.find_by(id: document.id)).to be_nil
    Current.tenant = nil
  end
end
