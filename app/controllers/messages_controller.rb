# One flat, tenant-wide feed rather than named threads — right scale for
# a two-person team. Comment's commentable pointed at the Tenant itself
# gives this for free, no new table (see Comment/Commentable, Phase 2).
class MessagesController < ApplicationController
  def index
    @messages = Current.tenant.comments.order(created_at: :desc)
  end

  def create
    @message = Current.tenant.comments.new(message_params)
    @message.author = Current.user

    if @message.save
      redirect_to messages_path, notice: "Posted."
    else
      # nosemgrep: ruby.rails.security.audit.xss.avoid-redirect.avoid-redirect
      # Destination is the fixed messages_path; only the alert text is
      # dynamic (validation error messages).
      redirect_to messages_path, alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def message_params
    params.require(:comment).permit(:body)
  end
end
