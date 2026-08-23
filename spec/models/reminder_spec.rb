require "rails_helper"

RSpec.describe Reminder do
  let(:tenant) { create(:tenant) }
  let(:creator) { create(:user, tenant: tenant) }

  around do |example|
    Current.tenant = tenant
    example.run
    Current.tenant = nil
  end

  describe "#deliver!" do
    it "notifies the creator and marks itself delivered" do
      reminder = create(:reminder, tenant: tenant, created_by: creator, message: "Renew the domain")

      expect { reminder.deliver! }.to change { Notification.count }.by(1)

      expect(reminder.status).to eq("delivered")
      notification = Notification.order(:id).last
      expect(notification.recipient).to eq(creator)
      expect(notification.message).to eq("Renew the domain")
    end
  end

  describe ".pending.due" do
    it "includes only pending reminders at or before now" do
      due = create(:reminder, tenant: tenant, created_by: creator, remind_at: 1.minute.ago)
      not_yet_due = create(:reminder, tenant: tenant, created_by: creator, remind_at: 1.hour.from_now)
      already_delivered = create(:reminder, tenant: tenant, created_by: creator, remind_at: 1.minute.ago, status: "delivered")

      expect(Reminder.pending.due).to contain_exactly(due)
      expect(Reminder.pending.due).not_to include(not_yet_due, already_delivered)
    end
  end
end
