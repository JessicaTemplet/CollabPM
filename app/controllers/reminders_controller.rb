class RemindersController < ApplicationController
  def index
    @reminders = Current.tenant.reminders.order(:remind_at)
  end

  def create
    @reminder = Current.tenant.reminders.new(reminder_params)
    @reminder.created_by = Current.user

    if @reminder.save
      redirect_to reminders_path, notice: "Reminder set."
    else
      # nosemgrep: ruby.rails.security.audit.xss.avoid-redirect.avoid-redirect
      # Destination is the fixed reminders_path; only the alert text is
      # dynamic (validation error messages).
      redirect_to reminders_path, alert: @reminder.errors.full_messages.to_sentence
    end
  end

  private

  def reminder_params
    params.require(:reminder).permit(:remind_at, :message)
  end
end
