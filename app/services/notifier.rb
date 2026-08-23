# The one place anything that wants to notify a user calls into —
# Reminders, @mentions, activity-log events — so delivery channels get
# added here once instead of three times. Currently just the in-app feed
# (a Notification row); web push and email digest are future channels
# that belong in this same method, not bolted onto each caller.
module Notifier
  def self.notify(recipient:, kind:, message:, notifiable: nil)
    Notification.create!(recipient: recipient, kind: kind, message: message, notifiable: notifiable)
  end
end
