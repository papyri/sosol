class HgvBiblioIdentifiersController < HgvMetaIdentifiersController
  before_filter :authorize
  before_filter :find_identifier, :only => [:edit, :update]
  after_filter :render_quick_help, :only => [:edit]

  def edit
    @identifier.retrieve_bibliographical_data # todo: should actually be called implicitly during initialisation time
  end

  def update
    prune_params

    comment = (params[:comment] && (params[:comment].strip.length > 0)) ? params[:comment].strip : 'update bibliographical information'

    @identifier.set_epidoc params[:hgv_biblio_identifier][:main], params[:hgv_biblio_identifier][:secondary], comment
    save_comment comment
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

    def render_quick_help      
      index = 0
      response.body = response.body.gsub(/(<span.+?class=["']quick_help["'].+?id=["'])(.+?)(["']>.+?<\/span>)/) {|match|
        i18n_id = $2
        element_id = i18n_id + '_' + index.to_s
        index += 1
        '<span class="quickHelp"><span class="hook" onmouseover="Effect.Appear(\'' + element_id + '\');" onmouseout="Effect.Fade(\'' + element_id + '\');">?</span><span class="message" id="' + element_id + '" style="display: none;">' + I18n.t(i18n_id) + '</span></span>'
      }
    end

end
