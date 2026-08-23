require "rails_helper"

RSpec.describe Notification do
  let(:tenant) { create(:tenant) }

  around do |example|
    Current.tenant = tenant
    example.run
    Current.tenant = nil
  end

  describe "#read!" do
    it "sets read_at once and is idempotent" do
      notification = create(:notification, tenant: tenant)

      notification.read!
      first_read_at = notification.read_at
      notification.read!

      expect(notification.read_at).to eq(first_read_at)
    end
  end

  describe ".unread" do
    it "excludes notifications with read_at set" do
      unread = create(:notification, tenant: tenant)
      read = create(:notification, tenant: tenant, read_at: Time.current)

      expect(Notification.unread).to contain_exactly(unread)
      expect(Notification.unread).not_to include(read)
    end
  end
end
