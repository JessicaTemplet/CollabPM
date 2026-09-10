module ApplicationHelper
  # Every status-like enum in this app (proposal status, outreach status,
  # invite status, reminder status) collapses to one of four tones so they
  # all read consistently as badges without a CSS rule per literal value.
  def status_tone(status)
    case status.to_s
    when "done", "approved", "converted", "active", "connected" then "positive"
    when "in_progress", "changes_requested", "contacted", "responded", "planned", "pending" then "progress"
    when "denied", "declined", "expired" then "negative"
    else "neutral"
    end
  end
end
