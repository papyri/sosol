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
  
  def preview
    find_identifier
    @identifier.get_epidoc_attributes
  end

  def autocomplete
    filename = {
      :provenance_ancientFindspot => 'ancientFindspot.xml',
      :provenance_modernFindspot  => 'modernFindspot.xml',
      :provenance_nome            => 'nomeList.xml',
      :provenance_ancientRegion   => 'ancientRegion.xml'}[params[:key].to_sym]
    xpath = {
      :provenance_ancientFindspot => '/TEI/body/list/item/placeName[@type="ancientFindspot"]',
      :provenance_modernFindspot  => '/TEI/body/list/item/placeName[@type="modernFindspot"]',
      :provenance_nome            => '/nomeList/nome/name',
      :provenance_ancientRegion   => '/TEI/body/list/item/placeName[@type="ancientRegion"]'}[params[:key].to_sym]    
    pattern  = params[params[:key]]
    max      = 10

    @autocompleter_list = []
      
    doc = REXML::Document.new(File.open(File.join(RAILS_ROOT, 'data', 'lookup', filename), 'r'))
    doc.elements.each(xpath) {|element|
      if (@autocompleter_list.length < max) && (element.text =~ Regexp.new('\A' + pattern)) 
        @autocompleter_list[@autocompleter_list.length] = element.text
      end
    }  

    render :layout => false
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

  protected

    def prune_params

      if params[:hgv_meta_identifier]

        # get rid of empty publication parts
        if params[:hgv_meta_identifier][:publicationExtra]
          params[:hgv_meta_identifier][:publicationExtra].delete_if{|index, extra|
            extra[:value].empty?
          }
        end

        if params[:hgv_meta_identifier][:textDate]
          
          # get rid of empty (invalid) date items
          params[:hgv_meta_identifier][:textDate].delete_if{|index, date|
            date[:c].empty? && date[:y].empty? && !date[:unknown]
          }

          # get rid of unnecessary date attribute @xml:id if there is only one date
          if params[:hgv_meta_identifier][:textDate].length == 1
            params[:hgv_meta_identifier][:textDate]['0'][:attributes][:id] = nil
          end
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

        # get rid of empty (invalid) provenance items
        if params[:hgv_meta_identifier][:provenance]
          params[:hgv_meta_identifier][:provenance].delete_if{|index, provenance|
            if provenance[:value] == 'unbekannt'
              if provenance[:children] && provenance[:children][:place]
                provenance[:children][:place] = {}
              end
              false
            else
              if !provenance[:children]
                true
              elsif !provenance[:children][:place]

                true
              else
                provenance[:children][:place].delete_if {|indexPlace, place|
                  if !place[:children]
                    true
                  elsif !place[:children][:location]
                    true
                  elsif !place[:children][:location][:value]
                    true
                  else
                    place[:children][:location][:value].empty? ? true : false
                  end
                }
                provenance[:children][:place].empty? ? true : false
              end
            end
          }
        end

      end

    end

    def complement_params

      if params[:hgv_meta_identifier]

        if params[:hgv_meta_identifier][:textDate]
          params[:hgv_meta_identifier][:textDate].each{|index, date| # for each textDate, i.e. X, Y, Z
            date[:id] = date[:attributes][:id]
            date.delete_if {|k,v| !v.instance_of?(String) || v.empty? }
            params[:hgv_meta_identifier][:textDate][index] = HgvDate.hgvToEpidoc date
          }
        end
        
        if params[:hgv_meta_identifier][:mentionedDate]
          params[:hgv_meta_identifier][:mentionedDate].each{|index, date|
            if date[:children] && date[:children][:date] && date[:children][:date][:attributes]
              date[:children][:date][:value] = HgvFormat.formatDateFromIsoParts(date[:children][:date][:attributes][:when], date[:children][:date][:attributes][:notBefore], date[:children][:date][:attributes][:notAfter])
            end
          }
        end

        if params[:hgv_meta_identifier][:provenance] && params[:hgv_meta_identifier][:provenance].kind_of?(Hash)
          params[:hgv_meta_identifier] && params[:hgv_meta_identifier][:provenance].each {|index, provenance|
            if provenance[:children] && provenance[:children][:place] && provenance[:children][:place].kind_of?(Hash)
              provenance[:children][:place].each{|indexPlace, place|
                if place[:attributes] && place[:attributes][:type] && place[:attributes][:type] == 'ancientRegion'
                  if place[:children] && place[:children][:location] && place[:children][:location][:value]
                    
                    doc = REXML::Document.new(File.open(File.join(RAILS_ROOT, 'data', 'lookup', 'ancientRegion.xml'), 'r'))
                    key = doc.elements['/TEI/body/list[@type="ancientRegion"]/item/placeName[@type="ancientRegion"][text()="' + place[:children][:location][:value] + '"]/@key']
  
                    if key && !key.value.empty?
                      place[:children][:location][:attributes] = {:key => key.value}
                    end
                  end
                end
              }
            end
          }
        end

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
