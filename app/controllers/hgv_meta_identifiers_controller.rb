class HgvMetaIdentifiersController < IdentifiersController
  layout 'site'
  before_filter :authorize
  
  def edit
    find_identifier
    @identifier.get_epidoc_attributes
  end
  
  def update
    find_identifier
    @identifier.set_epidoc(params[:hgv_meta_identifier], params[:comment])
    
    save_comment params[:comment]
    
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit)
  end
  
  protected
    def save_comment comment
      if comment != nil && comment.strip != ""
        @comment = Comment.new( {:git_hash => "todo", :user_id => @current_user.id, :identifier_id => @identifier.id, :publication_id => @identifier.publication_id, :comment => comment, :reason => "commit" } )
        @comment.save
      end
    end

    def find_identifier
      @identifier = HGVMetaIdentifier.find(params[:id])
    end
end
