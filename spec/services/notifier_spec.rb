require "rails_helper"

RSpec.describe Notifier do
  let(:tenant) { create(:tenant) }

  around do |example|
    Current.tenant = tenant
    example.run
    Current.tenant = nil
  end

  it "creates an in-app notification for the recipient" do
    recipient = create(:user, tenant: tenant)

    notification = Notifier.notify(recipient: recipient, kind: "mention", message: "You were mentioned in a comment.")

    expect(notification).to be_persisted
    expect(notification.recipient).to eq(recipient)
    expect(notification.read_at).to be_nil
  end
end
