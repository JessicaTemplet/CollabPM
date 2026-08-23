class FilesController < ApplicationController
  def index
    @files = Current.tenant.shared_files.attachments.order(created_at: :desc)
  end

  def create
    Current.tenant.shared_files.attach(params.require(:file))
    redirect_to files_path, notice: "File uploaded."
  end

  def destroy
    # Scoped through the tenant's own attachments, not a bare
    # ActiveStorage::Attachment.find — an attachment id from another
    # tenant must 404 here, not just fail silently.
    Current.tenant.shared_files.attachments.find(params[:id]).purge
    redirect_to files_path, notice: "File removed."
  end
end
