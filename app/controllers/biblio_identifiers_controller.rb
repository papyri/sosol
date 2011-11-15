include BiblioIdentifierHelper
class BiblioIdentifiersController < IdentifiersController

  def edit
    @is_editor_view = true
    find_identifier    
  end
  
  def preview
    @is_editor_view = true
    find_identifier
  end
  
  def update
    find_identifier
    begin
      commit_sha = @identifier.set_epidoc(params[:biblio_identifier], params[:comment])

      expire_publication_cache
      generate_flash_message
    rescue JRubyXML::ParseError => e
      flash[:error] = "Error updating file: #{e.message}. This file was NOT SAVED."
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   :action => :edit)
      return
    end
    
    save_comment(params[:comment], commit_sha)
    
    flash[:expansionSet] = params[:expansionSet]

    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit)
  end

  protected
  
  def find_identifier
    @identifier = BiblioIdentifier.find(params[:id])
  end
  
  def getBiblioPath biblioId
    'Biblio/' + (biblioId.to_i / 1000.0).ceil.to_s + '/'  + biblioId.to_s + '.xml' 
  end

  # Copypasted from HgvMetaIdentifiersController
  def generate_flash_message
    flash[:notice] = "File updated."
    if %w{new editing}.include? @identifier.publication.status
      flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
    end      
  end

  # Copypasted from HgvMetaIdentifiersController
  def save_comment (comment, commit_sha)
    if comment != nil && comment.strip != ""
      @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.id, :publication_id => @identifier.publication_id, :comment => comment, :reason => "commit" } )
      @comment.save
    end
  end

end
