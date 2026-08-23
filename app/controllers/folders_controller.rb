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

  private

  def folder_params
    params.require(:folder).permit(:name, :parent_id)
  end
end
