include HgvMetaIdentifierHelper
class HgvMetaIdentifiersController < IdentifiersController
  layout 'site'
  before_filter :authorize
  before_filter :prune_params, :only => [:update, :get_date_preview]
  before_filter :complement_params, :only => [:update, :get_date_preview]

  def edit
    find_identifier
    @identifier.get_epidoc_attributes
  end

  def get_date_preview
    @updates = {}

    [:X, :Y, :Z].each{|dateId|
     index = ('X'[0] - dateId.to_s[0]).abs.to_s
       if params[:hgv_meta_identifier][:textDate][index]
         @updates[dateId] = {
           :when      => params[:hgv_meta_identifier][:textDate][index][:attributes][:when],
           :notBefore => params[:hgv_meta_identifier][:textDate][index][:attributes][:notBefore],
           :notAfter  => params[:hgv_meta_identifier][:textDate][index][:attributes][:notAfter],
           :format   => params[:hgv_meta_identifier][:textDate][index][:value]
         }
       end
    }
        
    respond_to do |format|
      format.js
    end
  end
  
  def update
    find_identifier

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
    
    flash[:expansionSet] = params[:expansionSet]

    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit)
  end

  protected

    def prune_params

      if params[:hgv_meta_identifier]

        # get rid of empty (invalid) date items
        if params[:hgv_meta_identifier][:textDate]
          params[:hgv_meta_identifier][:textDate].delete_if{|index, date|
            date[:c].empty? && date[:y].empty? && !date[:unknown]
          }
        end

        # get rid of empty certainties for mentioned dates (X, Y, Z)
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

      if params[:hgv_meta_identifier] && params[:hgv_meta_identifier][:textDate]
        params[:hgv_meta_identifier][:textDate].each{|index, date| # for each textDate, i.e. X, Y, Z
          date[:id] = date[:attributes][:id]
          date.delete_if {|k,v| !v.instance_of?(String) || v.empty? }
          params[:hgv_meta_identifier][:textDate][index] = HgvDate.hgvToEpidoc date
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

end
