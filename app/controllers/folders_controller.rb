class FoldersController < ApplicationController
  def create
    @folder = Current.tenant.folders.new(folder_params)

    if @folder.save
      redirect_to documents_path(folder_id: @folder.parent_id), notice: "Folder created."
    else
      redirect_to documents_path(folder_id: @folder.parent_id), alert: @folder.errors.full_messages.to_sentence
    end
  end

  private

  def folder_params
    params.require(:folder).permit(:name, :parent_id)
  end
end
