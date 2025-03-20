# frozen_string_literal: true

module Alchemy
  module Admin
    class AttachmentsController < ResourcesController
      include UploaderResponses
      include ArchiveOverlay

      add_alchemy_filter :by_file_type, type: :select, options: ->(query) do
        query.result.distinct.pluck(:file_mime_type)
          .map { |type| [Alchemy.t(type, scope: "mime_types"), type] }
          .sort_by(&:first)
      end
      add_alchemy_filter :recent, type: :checkbox
      add_alchemy_filter :last_upload, type: :checkbox
      add_alchemy_filter :without_tag, type: :checkbox

      helper "alchemy/admin/tags"

      before_action(only: :assign) do
        @attachment = Attachment.find(params[:id])
      end

      def index
        @query = Attachment.ransack(search_filter_params[:q])
        @query.sorts = "name asc" if @query.sorts.empty?
        @attachments = @query.result

        if search_filter_params[:tagged_with].present?
          @attachments = @attachments.tagged_with(search_filter_params[:tagged_with])
        end

        @attachments = @attachments
          .page(params[:page] || 1)
          .per(items_per_page)

        if in_overlay?
          archive_overlay
        end
      end

      # The resources controller renders the edit form as default for show actions.
      def show
        render :show
      end

      def create
        @attachment = Attachment.create(attachment_attributes)
        handle_uploader_response(status: :created)
      end

      def update
        @attachment.update(attachment_attributes)
        if attachment_attributes["file"].present?
          handle_uploader_response(status: :accepted)
        else
          render_errors_or_redirect(
            @attachment,
            admin_attachments_path(search_filter_params),
            Alchemy.t("File successfully updated")
          )
        end
      end

      def destroy
        name = @attachment.name
        @attachment.destroy
        @url = admin_attachments_url(search_filter_params)
        flash[:notice] = Alchemy.t("File deleted successfully", name: name)
      end

      def download
        @attachment = Attachment.find(params[:id])
        send_file @attachment.file.path, {
          filename: @attachment.file_name,
          type: @attachment.file_mime_type
        }
      end

      private

      def search_filter_params
        @_search_filter_params ||= params.except(*COMMON_SEARCH_FILTER_EXCLUDES + [:attachment]).permit(
          *common_search_filter_includes + [
            :form_field_id
          ]
        )
      end

      def handle_uploader_response(status:)
        if @attachment.valid?
          render successful_uploader_response(file: @attachment, status: status)
        else
          render failed_uploader_response(file: @attachment)
        end
      end

      def attachment_attributes
        params.require(:attachment).permit(:file, :name, :file_name, :tag_list)
      end
    end
  end
end
