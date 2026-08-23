require "rails_helper"

RSpec.describe Comment do
  let(:tenant) { create(:tenant) }

  around do |example|
    Current.tenant = tenant
    example.run
    Current.tenant = nil
  end

  it "is valid with a body, author, and commentable" do
    expect(build(:comment, tenant: tenant)).to be_valid
  end

  it "requires a body" do
    comment = build(:comment, tenant: tenant, body: nil)
    expect(comment).not_to be_valid
  end

  it "does not leak across tenants" do
    other_tenant = create(:tenant)
    Current.tenant = other_tenant
    other_comment = create(:comment, tenant: other_tenant)
    Current.tenant = tenant

    expect(Comment.where(id: other_comment.id)).to be_empty
  end

  it "can be attached to any commentable, e.g. the tenant itself for a shared feed" do
    comment = create(:comment, tenant: tenant, commentable: tenant)
    expect(comment.commentable).to eq(tenant)
  end
end
