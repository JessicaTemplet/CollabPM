require "rails_helper"

RSpec.describe Folder do
  let(:tenant) { create(:tenant) }

  around do |example|
    Current.tenant = tenant
    example.run
    Current.tenant = nil
  end

  it "requires a name" do
    expect(build(:folder, tenant: tenant, name: nil)).not_to be_valid
  end

  it "can nest under a parent folder in the same tenant" do
    parent = create(:folder, tenant: tenant)
    child = build(:folder, tenant: tenant, parent: parent)

    expect(child).to be_valid
  end

  it "rejects a parent folder from a different tenant" do
    other_tenant = create(:tenant)
    Current.tenant = other_tenant
    foreign_parent = create(:folder, tenant: other_tenant)
    Current.tenant = tenant

    child = build(:folder, tenant: tenant, parent: foreign_parent)

    expect(child).not_to be_valid
  end

  it "nullifies documents' folder_id when the folder is destroyed" do
    folder = create(:folder, tenant: tenant)
    document = create(:document, tenant: tenant, folder: folder)

    folder.destroy!

    expect(document.reload.folder_id).to be_nil
  end
end
