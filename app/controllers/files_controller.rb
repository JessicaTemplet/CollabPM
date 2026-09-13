class FilesController < ApplicationController
  MAX_FILENAME_LENGTH = 255

  def index
    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    # Scoped to Current.tenant, the app's tenant-isolation boundary — the
    # rule only recognizes current_user.* scoping, not this pattern.
    @folder = params[:folder_id].present? ? Current.tenant.file_folders.find(params[:folder_id]) : nil
    @folders = Current.tenant.file_folders.where(parent_id: @folder&.id).order(:name)
    @files = Current.tenant.shared_files.where(file_folder_id: @folder&.id).order(created_at: :desc)
  end

  def create
    uploads = Array(params[:file]).select(&:present?)

    if uploads.empty?
      return redirect_to files_path(folder_id: params[:folder_id]), alert: "Choose at least one file."
    end

    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    target_folder = params[:folder_id].present? ? Current.tenant.file_folders.find(params[:folder_id]) : nil
    relative_paths = parsed_relative_paths
    folder_cache = {}

    uploads.each_with_index do |upload, index|
      segments = relative_paths[index].to_s.split("/").reject(&:blank?)
      filename = segments.pop
      destination_folder = resolve_upload_folder(target_folder, segments, folder_cache)

      shared_file = Current.tenant.shared_files.create!(file_folder: destination_folder)
      shared_file.file.attach(
        io: upload.tempfile,
        filename: sanitize_filename(filename.presence || upload.original_filename),
        content_type: upload.content_type
      )
    end

    redirect_to files_path(folder_id: target_folder&.id), notice: upload_notice(uploads.size)
  end

  def update
    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    # Scoped through the tenant's own shared_files, not a bare
    # SharedFile.find — a file id from another tenant must 404 here, not
    # just fail to rename.
    shared_file = Current.tenant.shared_files.find(params[:id])
    shared_file.file.blob.update!(filename: sanitize_filename(params[:filename]))
    redirect_to files_path(folder_id: shared_file.file_folder_id), notice: "File renamed."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to files_path(folder_id: shared_file&.file_folder_id), alert: e.record.errors.full_messages.to_sentence
  end

  def destroy
    # nosemgrep: ruby.rails.security.brakeman.check-unscoped-find.check-unscoped-find
    # Scoped through the tenant's own shared_files — see update above.
    shared_file = Current.tenant.shared_files.find(params[:id])
    folder_id = shared_file.file_folder_id
    shared_file.destroy
    redirect_to files_path(folder_id: folder_id), notice: "File removed."
  end

  private

  # Reconstructs a dropped/picked folder's structure as real FileFolder
  # records under wherever the upload started from, memoizing per
  # (parent, name) within this request so a batch of files that share
  # intermediate folders (e.g. 200 photos under the same "2024/") don't
  # each trigger their own lookup-or-create round trip.
  def resolve_upload_folder(base_folder, segment_names, cache)
    segment_names.reduce(base_folder) do |parent, raw_name|
      name = sanitize_filename(raw_name)
      cache[[ parent&.id, name ]] ||= Current.tenant.file_folders.find_or_create_by!(parent_id: parent&.id, name: name)
    end
  end

  def parsed_relative_paths
    JSON.parse(params[:relative_paths_json].presence || "[]")
  rescue JSON::ParserError
    []
  end

  # Display metadata only (ActiveStorage stores blobs under a
  # content-addressed key, never this string, and FileFolder names are
  # just a column, not a filesystem path), so there's no traversal risk
  # to the underlying storage — this just keeps what's shown sane.
  def sanitize_filename(name)
    cleaned = name.to_s.delete("\u0000").sub(%r{\A/+}, "").gsub("../", "")
    cleaned.presence&.first(MAX_FILENAME_LENGTH) || "untitled"
  end

  def upload_notice(count)
    count == 1 ? "File uploaded." : "#{count} files uploaded."
  end
end
