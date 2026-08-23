class ProjectInfoItemsController < ApplicationController
  def index
    @items_by_kind = ProjectInfoItem::KINDS.index_with { |kind| Current.tenant.project_info_items.where(kind: kind).order(:name) }
  end

  def create
    @item = Current.tenant.project_info_items.new(item_params)
    @item.created_by = Current.user

    if @item.save
      redirect_to project_info_items_path, notice: "Added."
    else
      # nosemgrep: ruby.rails.security.audit.xss.avoid-redirect.avoid-redirect
      # Destination is the fixed project_info_items_path; only the alert
      # text is dynamic (validation error messages).
      redirect_to project_info_items_path, alert: @item.errors.full_messages.to_sentence
    end
  end

  def destroy
    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    # Scoped to Current.tenant, the app's tenant-isolation boundary.
    Current.tenant.project_info_items.find(params[:id]).destroy
    redirect_to project_info_items_path, notice: "Removed."
  end

  private

  def item_params
    params.require(:project_info_item).permit(:kind, :name, details: {})
  end
end
