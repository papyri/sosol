include BiblioIdentifierHelper
class BiblioIdentifiersController < IdentifiersController
  # @RB: please see to that there all the standard actions available, such as update, preview and edit and that they have access to the identifier record as well as the EpiDoc
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
    #exit
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

end
