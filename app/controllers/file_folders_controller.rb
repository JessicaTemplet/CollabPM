class FileFoldersController < ApplicationController
  def create
    @folder = Current.tenant.file_folders.new(folder_params)

    if @folder.save
      redirect_to files_path(folder_id: @folder.parent_id), notice: "Folder created."
    else
      redirect_to files_path(folder_id: @folder.parent_id), alert: @folder.errors.full_messages.to_sentence
    end
  end

  def update
    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    # Scoped to Current.tenant — a folder id from another tenant must
    # 404 here, not just fail to rename.
    @folder = Current.tenant.file_folders.find(params[:id])

    if @folder.update(rename_params)
      redirect_to files_path(folder_id: @folder.parent_id), notice: "Folder renamed."
    else
      redirect_to files_path(folder_id: @folder.parent_id), alert: @folder.errors.full_messages.to_sentence
    end
  end

  def destroy
    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    # Scoped to Current.tenant — see update above.
    @folder = Current.tenant.file_folders.find(params[:id])
    parent_id = @folder.parent_id
    @folder.destroy
    redirect_to files_path(folder_id: parent_id), notice: "Folder deleted."
  end

  private

  def folder_params
    params.require(:file_folder).permit(:name, :parent_id)
  end

  def rename_params
    params.require(:file_folder).permit(:name)
  end
end
