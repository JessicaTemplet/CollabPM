require "rails_helper"

RSpec.describe "Shared files", type: :request do
  let(:tenant) { create(:tenant, subdomain: "acme") }
  let(:owner) do
    Current.tenant = tenant
    create(:user, tenant: tenant, email_address: "owner@acme.test",
                  password: "password123", password_confirmation: "password123")
  end
  let(:upload) { fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.txt"), "text/plain") }

  before do
    owner
    Current.tenant = nil
    host! "#{tenant.subdomain}.example.com"
    post session_path, params: { email_address: "owner@acme.test", password: "password123" }
  end

  it "uploads and lists a file" do
    post files_path, params: { file: upload }
    expect(response).to redirect_to(files_path)

    get files_path

    expect(response.body).to include("sample.txt")
  end

  it "removes an uploaded file" do
    post files_path, params: { file: upload }
    Current.tenant = tenant
    attachment = tenant.reload.shared_files.attachments.last
    Current.tenant = nil

    delete file_path(attachment)

    expect(response).to redirect_to(files_path)
    Current.tenant = tenant
    expect(tenant.reload.shared_files.attachments).to be_empty
    Current.tenant = nil
  end

  it "404s deleting another tenant's file" do
    other_tenant = create(:tenant, subdomain: "beta")
    Current.tenant = other_tenant
    other_tenant.shared_files.attach(upload)
    foreign_attachment = other_tenant.shared_files.attachments.last
    Current.tenant = nil

    delete file_path(foreign_attachment)

    expect(response).to have_http_status(:not_found)
  end
end
