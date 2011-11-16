module Alchemy
	module Admin
		class ContentsController < Alchemy::Admin::BaseController

			helper 'alchemy/contents'

			def new
				@element = Element.find(params[:element_id])
				@contents = @element.available_contents
				@content = @element.contents.build
				render :layout => false
			end

			def create
				@element = Element.find(params[:content][:element_id])
				@content = Content.create_from_scratch(@element, params[:content])
				@options = params[:options]
				# If options params come from Flash uploader then we have to parse them as hash.
				if @options.is_a?(String)
					@options = Rack::Utils.parse_query(@options)
				end
				if @content.essence_type == "EssencePicture"
					@content.essence.picture = Picture.find(params[:picture_id])
					@content.essence.save
					@contents_of_this_type = @element.contents.find_all_by_essence_type('EssencePicture')
					@dragable = @contents_of_this_type.length > 1
					@options = @options.merge(
						:dragable => @dragable
					) if @options
				end
			end

			def update
				content = Content.find(params[:id])
				content.essence.update_attributes(params[:content])
			end

			def order
				for id in params[:content_ids]
					content = Content.find(id)
					content.move_to_bottom
				end
				@notice = _("Successfully saved content position")
			end

			def destroy
				content = Content.find(params[:id])
				element = content.element
				content_name = content.name
				@content_dom_id = "#{content.essence_type.underscore}_#{content.id}"
				@notice = _("Successfully deleted %{content}") % {:content => content_name}
				content.destroy
			end
  
		end
	end
end
