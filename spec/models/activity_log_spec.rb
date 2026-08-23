require "rails_helper"

RSpec.describe ActivityLog do
  let(:tenant) { create(:tenant) }

  around do |example|
    Current.tenant = tenant
    example.run
    Current.tenant = nil
  end

  describe ".record!" do
    it "creates a log entry with actor, action, subject, and payload" do
      actor = create(:user, tenant: tenant)
      subject_tag = create(:tag, tenant: tenant)

      log = ActivityLog.record!(actor: actor, action: "tag.created", subject: subject_tag, payload: { name: subject_tag.name })

      expect(log.actor).to eq(actor)
      expect(log.subject).to eq(subject_tag)
      expect(log.payload).to eq("name" => subject_tag.name)
    end

    it "allows a nil subject" do
      actor = create(:user, tenant: tenant)
      expect(ActivityLog.record!(actor: actor, action: "session.login")).to be_persisted
    end
  end

  it "is append-only — updates are refused even though validations pass" do
    log = create(:activity_log, tenant: tenant)

    expect { log.update(action: "changed") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
