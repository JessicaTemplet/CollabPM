class EventsController < ApplicationController
  # The calendar is one view over two sources rather than a copy of
  # Proposal due dates into a second Event row — same principle as not
  # splitting Proposals/Tasks into two models. A due date lives on the
  # Proposal; the calendar just also queries proposals-with-due-dates and
  # merges them in for display.
  def index
    range = (Date.current.beginning_of_month)..(Date.current.end_of_month)

    @events = Current.tenant.events.where(start_at: range.first.beginning_of_day..range.last.end_of_day).order(:start_at)
    @proposals_due = Current.tenant.proposals.where(due_date: range).order(:due_date)
  end

  def create
    @event = Current.tenant.events.new(event_params)
    @event.created_by = Current.user

    if @event.save
      redirect_to events_path, notice: "Event created."
    else
      redirect_to events_path, alert: @event.errors.full_messages.to_sentence
    end
  end

  def destroy
    Current.tenant.events.find(params[:id]).destroy
    redirect_to events_path, notice: "Event removed."
  end

  private

  def event_params
    params.require(:event).permit(:title, :description, :start_at, :end_at, :all_day)
  end
end
