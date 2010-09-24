include HgvMetaIdentifierHelper
class HgvMetaIdentifiersController < IdentifiersController
  layout 'site'
  before_filter :authorize
  before_filter :find_identifier, :only => [:edit, :update]
  before_filter :prune_params, :only => [:update]
  before_filter :complement_params, :only => [:update]
  after_filter :render_quick_help, :only => [:edit]

  def edit
    find_identifier
    @identifier.get_epidoc_attributes
  end

  def update
    find_identifier
    prune_params
    complement_params

    begin
      commit_sha = @identifier.set_epidoc(params[:hgv_meta_identifier], params[:comment])
      expire_publication_cache
      generate_flash_message
    rescue JRubyXML::ParseError => e
      flash[:error] = "Error updating file: #{e.message}. This file was NOT SAVED."
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   :action => :edit)
      return
    end
    
    save_comment(params[:comment], commit_sha)

    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit)
  end

  protected

    def prune_params
      if params[:hgv_meta_identifier]
        params[:hgv_meta_identifier]['textDate'].each_pair{|index, date|
          ['onDate', 'fromDate', 'toDate'].each {|dateType|
            date['children'][dateType]['children'].delete 'offset' #todocl: remove this
            if date['children'][dateType]['children']['century']['value'].empty? &&
               date['children'][dateType]['children']['year']['value'].empty? &&
               date['children'][dateType]['children']['month']['value'].empty? &&
               date['children'][dateType]['children']['day']['value'].empty?
              date['children'].delete dateType
            end
          }
  
          if !date['children']['onDate'] &&
             !(date['children']['fromDate'] && date['children']['toDate'])
           params[:hgv_meta_identifier]['textDate'].delete index
          end
  
        }
        
        if params[:hgv_meta_identifier]['mentionedDate']
          params[:hgv_meta_identifier]['mentionedDate'].each_pair{|index, date|
            if date['children'] && date['children']['date'] && date['children']['date']['children'] && date['children']['date']['children']['certainty']
              date['children']['date']['children']['certainty'].each_pair{|certainty_index, certainty|
                if certainty['attributes'] && certainty['attributes']['relation'] && certainty['attributes']['relation'].empty?
                  date['children']['date']['children']['certainty'].delete certainty_index
                end
              }
            end
          }
        end
      end
    end

    def complement_params
      if params[:hgv_meta_identifier]
        params[:hgv_meta_identifier]['textDate'].each{|index, date|
          tasks = {}
  
          if date['children']['onDate']
            tasks[:chron] = date['children']['onDate']
          end
  
          if date['children']['fromDate']
            tasks[:chronMin] = date['children']['fromDate']
          elsif date['children']['onDate']
            tasks[:chronMin] = date['children']['onDate']
          end
  
          if date['children']['toDate']
            tasks[:chronMax] = date['children']['toDate']
          elsif date['children']['onDate']
            tasks[:chronMax] = date['children']['onDate']
          end
  
          tasks.each_pair{|chron, value|
            date['attributes'][{:chron => 'textDateWhen', :chronMin => 'textDateFrom', :chronMax => 'textDateTo'}[chron]] = HgvFuzzy.getChron(
              value['children']['century']['value'],
              value['children']['year']['value'],
              value['children']['month']['value'],
              value['children']['day']['value'],
              value['children']['century']['attributes']['extent'],
              value['children']['year']['attributes']['extent'],
              value['children']['month']['attributes']['extent'],
              chron
            )
  
          }
        }
      end
    end

    def generate_flash_message
      flash[:notice] = "File updated."
      if %w{new editing}.include? @identifier.publication.status
        flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
      end      
    end

    def save_comment (comment, commit_sha)
      if comment != nil && comment.strip != ""
        @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.id, :publication_id => @identifier.publication_id, :comment => comment, :reason => "commit" } )
        @comment.save
      end
    end

    def find_identifier
      @identifier = HGVMetaIdentifier.find(params[:id])
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
