class DocumentsController < ApplicationController
  def index
    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    # Scoped to Current.tenant, the app's tenant-isolation boundary — the
    # rule only recognizes current_user.* scoping, not this pattern.
    @folder = params[:folder_id].present? ? Current.tenant.folders.find(params[:folder_id]) : nil
    @folders = Current.tenant.folders.where(parent_id: @folder&.id).order(:name)
    @documents = Current.tenant.documents.where(folder_id: @folder&.id).order(:title)
  end

  def show
    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    # Scoped to Current.tenant — see index above.
    @document = Current.tenant.documents.find(params[:id])
  end

  def new
    @document = Current.tenant.documents.new(folder_id: params[:folder_id])
  end

  def create
    @document = Current.tenant.documents.new(document_params)

    if @document.save
      # nosemgrep: ruby.rails.security.audit.xss.avoid-redirect.avoid-redirect
      # Redirects to the created record itself (document_path(@document)),
      # not to a user-supplied URL.
      redirect_to @document, notice: "Document created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def document_params
    params.require(:document).permit(:title, :folder_id)
  end
end
