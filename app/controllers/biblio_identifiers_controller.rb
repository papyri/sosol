include BiblioIdentifierHelper
class BiblioIdentifiersController < IdentifiersController
  layout 'site'

  # @RB: please see to that there all the standard actions available, such as update, preview and edit and that they have access to the identifier record as well as the EpiDoc
  def edit
    find_identifier    
  end
  
  def preview
    find_identifier
  end
  
  protected
  
  def find_identifier
    epiDocXml = if params[:id] && /^\d+$/ =~ params[:id]
      git = Grit::Repo.new(CANONICAL_REPOSITORY).commits.first.tree
      biblio = git / getBiblioPath(params[:id])
      biblio.data
    else
      test = case params[:test]
      when 'journal' then '1.xml'
      when 'book' then '3001.xml'
      when 'review' then '32110.xml'
      else 'biblioTest.xml'
      end

      epiDocFile = File.new(File.join(RAILS_ROOT, 'tmp/biblioTest', test), 'r')
      epiDocFile.read

    end
    
    @identifier = BiblioIdentifier.new(epiDocXml)
  end
  
  def getBiblioPath biblioId
    'Biblio/' + (biblioId.to_i / 1000.0).ceil.to_s + '/'  + biblioId.to_s + '.xml' 
  end

end
