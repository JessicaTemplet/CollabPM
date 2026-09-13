class FoldersController < ApplicationController
  def create
    @folder = Current.tenant.folders.new(folder_params)

    if @folder.save
      # nosemgrep: ruby.rails.security.audit.xss.avoid-redirect.avoid-redirect
      # Destination is documents_path; folder_id is an internal record id,
      # not an arbitrary redirect target.
      redirect_to documents_path(folder_id: @folder.parent_id), notice: "Folder created."
    else
      # nosemgrep: ruby.rails.security.audit.xss.avoid-redirect.avoid-redirect
      # Same destination as above; only the alert text is dynamic.
      redirect_to documents_path(folder_id: @folder.parent_id), alert: @folder.errors.full_messages.to_sentence
    end
  end

  def update
    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    # Scoped to Current.tenant — a folder id from another tenant must
    # 404 here, not just fail to rename.
    @folder = Current.tenant.folders.find(params[:id])

    if @folder.update(rename_params)
      redirect_to documents_path(folder_id: @folder.parent_id), notice: "Folder renamed."
    else
      redirect_to documents_path(folder_id: @folder.parent_id), alert: @folder.errors.full_messages.to_sentence
    end
  end

  def destroy
    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    # Scoped to Current.tenant — see update above.
    @folder = Current.tenant.folders.find(params[:id])
    parent_id = @folder.parent_id

    # Subfolders cascade with it (Folder has_many :children, dependent:
    # :destroy). Documents directly inside are nullified rather than
    # destroyed (Folder has_many :documents, dependent: :nullify) — they
    # move up to the parent folder instead of being deleted, which is
    # the existing model behavior this action is just exposing.
    @folder.destroy

    redirect_to documents_path(folder_id: parent_id), notice: "Folder deleted."
  end

  private

  def folder_params
    params.require(:folder).permit(:name, :parent_id)
  end

  def rename_params
    params.require(:folder).permit(:name)
  end
end
