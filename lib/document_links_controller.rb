class DocumentLinksController

	attr_accessor :show_comment, :show_submit, :show_delete, :show_edit, :show_finalize

	def initialize (show_comment = false,  show_edit = false, show_submit = false, show_finalize = false, show_delete = false)
		@show_comment = show_comment
		@show_submit = show_submit
		@show_delete = show_delete
		@show_edit = show_edit	
		@show_finalize = show_finalize
	end

end
