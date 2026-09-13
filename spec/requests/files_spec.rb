require "rails_helper"

RSpec.describe "Shared files", type: :request do
  let(:tenant) { create(:tenant, subdomain: "acme") }
  let(:owner) do
    Current.tenant = tenant
    create(:user, tenant: tenant, email_address: "owner@acme.test",
                  password: "password123", password_confirmation: "password123")
  end
  let(:upload) { fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.txt"), "text/plain") }
  let(:second_upload) { fixture_file_upload(Rails.root.join("spec/fixtures/files/sample2.txt"), "text/plain") }

  before do
    owner
    Current.tenant = nil
    host! "#{tenant.subdomain}.example.com"
    post session_path, params: { email_address: "owner@acme.test", password: "password123" }
  end

  it "uploads and lists a file at the root" do
    post files_path, params: { file: [ upload ] }
    expect(response).to redirect_to(files_path(folder_id: nil))

    get files_path

    expect(response.body).to include("sample.txt")
  end

  it "uploads multiple files at once" do
    post files_path, params: { file: [ upload, second_upload ] }

    get files_path

    expect(response.body).to include("sample.txt").and include("sample2.txt")
  end

  it "uploads into the folder currently being viewed" do
    Current.tenant = tenant
    folder = create(:file_folder, tenant: tenant, name: "Specs")
    Current.tenant = nil

    post files_path(folder_id: folder.id), params: { file: [ upload ] }
    expect(response).to redirect_to(files_path(folder_id: folder.id))

    get files_path(folder_id: folder.id)
    expect(response.body).to include("sample.txt")

    get files_path
    expect(response.body).not_to include("sample.txt")
  end

  it "recreates a dropped folder's structure as real nested folders" do
    post files_path, params: {
      file: [ upload, second_upload ],
      relative_paths_json: [ "docs/sample.txt", "docs/nested/sample2.txt" ].to_json
    }

    get files_path
    expect(response.body).to include("docs")
    expect(response.body).not_to include("sample.txt") # filed under docs/, not shown at root

    Current.tenant = tenant
    docs = FileFolder.find_by!(name: "docs", parent_id: nil)
    nested = FileFolder.find_by!(name: "nested", parent_id: docs.id)
    expect(docs.shared_files.map { |f| f.file.filename.to_s }).to eq([ "sample.txt" ])
    expect(nested.shared_files.map { |f| f.file.filename.to_s }).to eq([ "sample2.txt" ])
    Current.tenant = nil
  end

  it "rejects an upload with no files" do
    post files_path, params: {}

    expect(response).to redirect_to(files_path(folder_id: nil))
    follow_redirect!
    expect(response.body).to include("Choose at least one file")
  end

  it "shows a view link that opens the file inline rather than forcing a download" do
    post files_path, params: { file: [ upload ] }

    get files_path

    expect(response.body).to include(">View<")
    expect(response.body).to include("disposition=inline")
    expect(response.body).to include('target="_blank"')
  end

  it "renames an uploaded file" do
    post files_path, params: { file: [ upload ] }
    Current.tenant = tenant
    shared_file = tenant.reload.shared_files.last
    Current.tenant = nil

    patch file_path(shared_file), params: { filename: "renamed.txt" }

    expect(response).to redirect_to(files_path(folder_id: nil))
    Current.tenant = tenant
    expect(shared_file.reload.file.filename.to_s).to eq("renamed.txt")
    Current.tenant = nil
  end

  it "removes an uploaded file" do
    post files_path, params: { file: [ upload ] }
    Current.tenant = tenant
    shared_file = tenant.reload.shared_files.last
    Current.tenant = nil

    delete file_path(shared_file)

    expect(response).to redirect_to(files_path(folder_id: nil))
    Current.tenant = tenant
    expect(SharedFile.find_by(id: shared_file.id)).to be_nil
    Current.tenant = nil
  end

  it "404s deleting another tenant's file" do
    other_tenant = create(:tenant, subdomain: "beta")
    Current.tenant = other_tenant
    foreign_file = create(:shared_file, tenant: other_tenant)
    foreign_file.file.attach(upload)
    Current.tenant = nil

    delete file_path(foreign_file)

    expect(response).to have_http_status(:not_found)
  end

  it "404s renaming another tenant's file" do
    other_tenant = create(:tenant, subdomain: "beta")
    Current.tenant = other_tenant
    foreign_file = create(:shared_file, tenant: other_tenant)
    foreign_file.file.attach(upload)
    Current.tenant = nil

    patch file_path(foreign_file), params: { filename: "hijacked.txt" }

    expect(response).to have_http_status(:not_found)
  end

  describe "folders" do
    it "creates a folder" do
      post file_folders_path, params: { file_folder: { name: "New folder" } }

      expect(response).to redirect_to(files_path(folder_id: nil))
      Current.tenant = tenant
      expect(FileFolder.find_by(name: "New folder")).to be_present
      Current.tenant = nil
    end

    it "renames a folder" do
      Current.tenant = tenant
      folder = create(:file_folder, tenant: tenant, name: "Old name")
      Current.tenant = nil

      patch file_folder_path(folder), params: { file_folder: { name: "New name" } }

      expect(response).to redirect_to(files_path(folder_id: nil))
      Current.tenant = tenant
      expect(folder.reload.name).to eq("New name")
      Current.tenant = nil
    end

    it "deletes a folder along with the files inside it" do
      Current.tenant = tenant
      folder = create(:file_folder, tenant: tenant)
      shared_file = create(:shared_file, tenant: tenant, file_folder: folder)
      shared_file.file.attach(upload)
      Current.tenant = nil

      delete file_folder_path(folder)

      expect(response).to redirect_to(files_path(folder_id: nil))
      Current.tenant = tenant
      expect(FileFolder.find_by(id: folder.id)).to be_nil
      expect(SharedFile.find_by(id: shared_file.id)).to be_nil
      Current.tenant = nil
    end

    it "404s renaming another tenant's folder" do
      other_tenant = create(:tenant, subdomain: "beta")
      Current.tenant = other_tenant
      foreign_folder = create(:file_folder, tenant: other_tenant)
      Current.tenant = nil

      patch file_folder_path(foreign_folder), params: { file_folder: { name: "Hijacked" } }

      expect(response).to have_http_status(:not_found)
    end

    it "404s deleting another tenant's folder" do
      other_tenant = create(:tenant, subdomain: "beta")
      Current.tenant = other_tenant
      foreign_folder = create(:file_folder, tenant: other_tenant)
      Current.tenant = nil

      delete file_folder_path(foreign_folder)

      expect(response).to have_http_status(:not_found)
    end
  end
end
