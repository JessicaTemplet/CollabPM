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
      redirect_to reminders_path, alert: @reminder.errors.full_messages.to_sentence
    end
  end

  private

  def reminder_params
    params.require(:reminder).permit(:remind_at, :message)
  end
end
