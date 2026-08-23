class ProposalsController < ApplicationController
  def index
    scope = Current.tenant.proposals.order(created_at: :desc)
    scope = scope.where(assignee_id: Current.user.id) if params[:mine].present?
    @proposals_by_status = Proposal::STATUSES.index_with { |status| scope.select { |p| p.status == status } }
  end

  def show
    @proposal = Current.tenant.proposals.find(params[:id])
  end

  def new
    @proposal = Current.tenant.proposals.new
  end

  def create
    @proposal = Current.tenant.proposals.new(proposal_params)
    @proposal.created_by = Current.user

    if @proposal.save
      redirect_to @proposal, notice: "Proposal created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @proposal = Current.tenant.proposals.find(params[:id])
  end

  def update
    @proposal = Current.tenant.proposals.find(params[:id])

    if @proposal.update(proposal_params)
      redirect_to @proposal, notice: "Proposal updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def proposal_params
    params.require(:proposal).permit(:title, :description, :status, :assignee_id, :due_date)
  end
end
