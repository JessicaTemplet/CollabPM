require "rails_helper"

RSpec.describe DeliverDueRemindersJob do
  it "delivers each tenant's own due reminders, independently, and leaves not-yet-due ones alone" do
    tenant_a = create(:tenant)
    Current.tenant = tenant_a
    user_a = create(:user, tenant: tenant_a)
    due_a = create(:reminder, tenant: tenant_a, created_by: user_a, remind_at: 1.minute.ago)
    not_due_a = create(:reminder, tenant: tenant_a, created_by: user_a, remind_at: 1.hour.from_now)
    Current.tenant = nil

    tenant_b = create(:tenant)
    Current.tenant = tenant_b
    user_b = create(:user, tenant: tenant_b)
    due_b = create(:reminder, tenant: tenant_b, created_by: user_b, remind_at: 1.minute.ago)
    Current.tenant = nil

    described_class.new.perform

    Current.tenant = tenant_a
    expect(due_a.reload.status).to eq("delivered")
    expect(not_due_a.reload.status).to eq("pending")
    expect(Notification.where(recipient: user_a).count).to eq(1)
    Current.tenant = nil

    Current.tenant = tenant_b
    expect(due_b.reload.status).to eq("delivered")
    expect(Notification.where(recipient: user_b).count).to eq(1)
    Current.tenant = nil
  end
end
