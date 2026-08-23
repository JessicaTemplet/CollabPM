class OutreachContactsController < ApplicationController
  def index
    @contacts = Current.tenant.outreach_contacts.order(created_at: :desc)
  end

  def create
    @contact = Current.tenant.outreach_contacts.new(contact_params)
    @contact.created_by = Current.user

    if @contact.save
      redirect_to outreach_contacts_path, notice: "Contact added."
    else
      redirect_to outreach_contacts_path, alert: @contact.errors.full_messages.to_sentence
    end
  end

  def update
    @contact = Current.tenant.outreach_contacts.find(params[:id])
    @contact.update!(contact_params)
    redirect_to outreach_contacts_path, notice: "Updated."
  end

  private

  def contact_params
    params.require(:outreach_contact).permit(:name, :channel, :status, :kind, :budget_cents, :campaign_name)
  end
end
