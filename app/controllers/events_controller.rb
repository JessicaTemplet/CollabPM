class EventsController < ApplicationController
  # The calendar is one view over two sources rather than a copy of
  # Proposal due dates into a second Event row — same principle as not
  # splitting Proposals/Tasks into two models. A due date lives on the
  # Proposal; the calendar just also queries proposals-with-due-dates and
  # merges them in for display.
  def index
    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    @prev_month = @month.prev_month
    @next_month = @month.next_month

    # Grid runs Sunday-to-Saturday and pads into the adjacent months so the
    # calendar always renders full weeks, not a ragged first/last row.
    grid_start = @month.beginning_of_month - @month.beginning_of_month.wday.days
    grid_end = @month.end_of_month + (6 - @month.end_of_month.wday).days

    events = Current.tenant.events
      .where(start_at: grid_start.beginning_of_day..grid_end.end_of_day)
      .order(:start_at)
    proposals_due = Current.tenant.proposals
      .where(due_date: grid_start..grid_end)
      .order(:due_date)

    events_by_day = events.group_by { |event| event.start_at.to_date }
    proposals_by_day = proposals_due.group_by(&:due_date)

    @weeks = (grid_start..grid_end).each_slice(7).map do |week|
      week.map do |date|
        {
          date: date,
          current_month: date.month == @month.month,
          today: date == Date.current,
          events: events_by_day[date] || [],
          proposals: proposals_by_day[date] || []
        }
      end
    end
  end

  def create
    @event = Current.tenant.events.new(event_params)
    @event.created_by = Current.user

    if @event.save
      redirect_to events_path(month: @event.start_at.to_date.strftime("%Y-%m")), notice: "Event created."
    else
      # nosemgrep: ruby.rails.security.audit.xss.avoid-redirect.avoid-redirect
      # Destination is the fixed events_path; only the flash alert text is
      # dynamic (validation error messages), not the redirect target.
      redirect_to events_path, alert: @event.errors.full_messages.to_sentence
    end
  end

  def destroy
    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    # Scoped to Current.tenant, the app's tenant-isolation boundary.
    event = Current.tenant.events.find(params[:id])
    month = event.start_at.to_date.strftime("%Y-%m")
    event.destroy
    redirect_to events_path(month: month), notice: "Event removed."
  end

  private

  def parse_month(value)
    return nil if value.blank?
    Date.strptime(value, "%Y-%m").beginning_of_month
  rescue ArgumentError
    nil
  end

  def event_params
    params.require(:event).permit(:title, :description, :start_at, :end_at, :all_day)
  end
end
