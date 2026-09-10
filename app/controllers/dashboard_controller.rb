class DashboardController < ApplicationController
  def index
    @stats = [
      { label: "Open Proposals", value: Current.tenant.proposals.where.not(status: %w[done denied]).count },
      { label: "Reminders Due", value: Current.tenant.reminders.pending.due.count },
      { label: "Unread Notifications", value: Notification.where(recipient: Current.user).unread.count },
      { label: "Team Members", value: Current.tenant.users.count },
    ]
    @activity = ActivityLog.includes(:actor).order(created_at: :desc).limit(6)
  end
end
