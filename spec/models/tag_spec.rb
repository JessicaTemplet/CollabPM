require "rails_helper"

RSpec.describe Tag do
  let(:tenant) { create(:tenant) }

  around do |example|
    Current.tenant = tenant
    example.run
    Current.tenant = nil
  end

  it "normalizes name to a stripped, downcased form" do
    tag = create(:tag, tenant: tenant, name: "  Urgent  ")
    expect(tag.name).to eq("urgent")
  end

  it "is unique per tenant, case-insensitively" do
    create(:tag, tenant: tenant, name: "urgent")
    dup = build(:tag, tenant: tenant, name: "URGENT")

    expect(dup).not_to be_valid
  end

  it "allows the same name in a different tenant" do
    create(:tag, tenant: tenant, name: "urgent")
    other_tenant = create(:tenant)
    Current.tenant = other_tenant

    expect(build(:tag, tenant: other_tenant, name: "urgent")).to be_valid
  end
end
