class HgvBiblioIdentifiersController < HgvMetaIdentifiersController
  before_filter :find_identifier, :only => [:edit, :update]

  def edit
    @identifier.retrieve_bibliographical_data # todo: should actually be called implicitly during initialisation time
  end

  def update
    prune_params

    comment = (params[:comment] && (params[:comment].strip.length > 0)) ? params[:comment].strip : 'update bibliographical information'

    commit_sha = @identifier.set_epidoc params[:hgv_biblio_identifier][:main], params[:hgv_biblio_identifier][:other], params[:hgv_biblio_identifier][:secondary], comment
    save_comment (comment, commit_sha)
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit)
  end

  protected

    def prune_params # removes all empty entries from other and secondary bibliographic data
      params[:hgv_biblio_identifier].each_pair{|type, data_list|
        if type != 'main'
          data_list.each_pair{|id, data|
            totally_empty = true
            data.each_pair {|key, value|
              if !value.strip.empty?
                totally_empty = false
              end
            }
            if totally_empty
              params[:hgv_biblio_identifier][type].delete(id) 
            end
          }
        end
      }
    end

    def find_identifier
      @identifier = HGVBiblioIdentifier.find(params[:id])
    end

end
