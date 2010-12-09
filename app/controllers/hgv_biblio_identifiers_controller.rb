class HgvBiblioIdentifiersController < HgvMetaIdentifiersController
  before_filter :authorize
  before_filter :find_identifier, :only => [:edit, :update]
  after_filter :render_quick_help, :only => [:edit]

  def edit
    find_identifier
    @biblio_identifier.retrieve_bibliographical_data # todo: should actually be called implicitly during initialisation time
    @identifier.get_epidoc_attributes
  end

  def update
    find_identifier

    commit_sha = @biblio_identifier.set_epidoc params[:hgv_biblio_identifier][:main], params[:hgv_biblio_identifier][:secondary], params[:comment]
    save_comment params[:comment], commit_sha

    #commit_sha = @identifier.set_epidoc(params[:hgv_meta_identifier], params[:comment])
    #save_comment params[:comment], commit_sha

    generate_flash_message

    redirect_to polymorphic_path([@biblio_identifier.publication, @biblio_identifier],
                                 :action => :edit)
  end

  protected

    def prune_params # removes all empty entries from other and secondary bibliographic data
      super

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
    
    def complement_params
      super

      if params[:comment].strip.empty?
        params[:comment] = 'update bibliographical information'
      else
        params[:comment].strip!
      end
    end

    def find_identifier
      @biblio_identifier = HGVBiblioIdentifier.find(params[:id])
      @identifier = HGVMetaIdentifier.find(params[:id])
    end

end
