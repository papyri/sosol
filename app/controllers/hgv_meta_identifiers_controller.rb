include HGVMetaIdentifierHelper

# Controller for all actions concerning the hgv metadata editor, such as edit, update, show preview and some json actions for interactive javascript
class HGVMetaIdentifiersController < IdentifiersController
  # uses standard layout
  # user must be logged in to access these actions
  before_action :authorize
  before_action :ownership_guard, only: %i[update updatexml]
  # before post data is used for further processing unwanted entries are discarded
  before_action :prune_params, only: %i[update get_date_preview]
  #  before post data is further processed some user entries are decorated with additional information, such as human readable format strings
  before_action :complement_params, only: %i[update get_date_preview]

  # Retrieves hgv identifier object from database and calls up HGV metadata editor
  # Assumes that incoming post respectively get parameters contain a valid hgv identifier id
  # Side effect on +@identifier+
  def edit
    find_identifier
    @identifier.get_epidoc_attributes
    @is_editor_view = true
  end

  # Retrieves hgv identifier object from database and updates its values from incoming post data, saves comment
  # Redirects back to the editor (see action edit)
  # Assumes that incoming post request contains new values for the hgv record that should be written back to EpiDoc
  # Side effect on +@identifier+ and +flash+
  # Writes to database and git repository, clears publication cache
  def update
    find_identifier
    # exit
    begin
      params.permit!
      commit_sha = @identifier.set_epidoc(params[:hgv_meta_identifier].to_h, params[:comment].to_s)
      expire_publication_cache
      generate_flash_message
    rescue JRubyXML::ParseError => e
      flash[:error] = "Error updating file: #{e.message}. This file was NOT SAVED."
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   action: :edit)
      return
    end

    save_comment(params[:comment].to_s, commit_sha)

    flash[:expansionSet] = params[:expansionSet]

    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 action: :edit)
  end

  # Retrieves an hgv identifier record by an incoming identifier id and creates a preview
  # Side effect on +@identifier+
  def preview
    find_identifier
    
    begin
      @identifier_html_preview = @identifier.preview
    rescue JRubyXML::ParseError => e
      flash[:error] = "Error parsing XML for preview. #{e.to_str}"
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   action: :editxml)
    end
    @is_editor_view = true
  end

  # Complements geo data, given a certain bit of geo data, it looks up complementary information from an xml reference file
  # Assumes that the user's request data contain type, subtype and value (e.g. ancient, nome, Arsinoites)
  # Result is rendered as json, that can be used to update fields of the editor
  # Side effect on +@complementer_list+

  # Retrieves a list of geo entries from an xml lookup file by pattern match at the beginnig of the string
  # Needs to know what kind of geoinformation should be looked up, i.e. type and subtype (e.g. modern findspot)
  # Type and subtype need to be passed in by post data
  # Side effect on +@autocompleter_list+

  # Provides a small data preview snippets (values for when, notBefore and notAfter as well as the hgv formatted value) for display within the hgv metadata editor
  # Assumes that hgv metadata is passed in via post and uses the values containd in hash entry »:textDate« to generate preview snippets for hgv date.
  # Side effect on +@update+
  def get_date_preview
    @updates = {}

    %i[X Y Z].each do |dateId|
      index = ('X'[0].ord - dateId.to_s[0].ord).abs.to_s
      next unless params[:hgv_meta_identifier][:textDate][index]

      @updates[dateId] = {
        when: params[:hgv_meta_identifier][:textDate][index][:attributes][:when],
        notBefore: params[:hgv_meta_identifier][:textDate][index][:attributes][:notBefore],
        notAfter: params[:hgv_meta_identifier][:textDate][index][:attributes][:notAfter],
        format: params[:hgv_meta_identifier][:textDate][index][:value]
      }
    end

    respond_to do |format|
      format.js
    end
  end

  # Takes user's geo data from post stream and generates a hgv formatted preview from it
  # Assumes that hgv post data (especially all data fields concerning provenance) is passed in
  # Side effect on +@identifier+ and +@update+
  def get_geo_preview
    @identifier = HGVMetaIdentifier.new
    params.permit!
    @identifier.populate_epidoc_attributes_from_attributes_hash params[:hgv_meta_identifier].to_h
    @update = HGVProvenance.format @identifier.non_database_attribute[:provenance]

    respond_to do |format|
      format.js
    end
  end

  protected

  # Gets rid of invalid user data that has been passed in, such as empty fields in publication information or dates don't provide enough information to be parsed as hgv dates
  # Assumes that the hgv metadata editor has been called to action and that its post data is passed in via post
  # Prunes post parameters for hash entries +:publicationExtra+, +:textDate+ and +:mentionedDate+
  # Side effect on params variable
  def prune_params
    if params[:hgv_meta_identifier]
      params[:hgv_meta_identifier].permit!

      # get rid of empty digital images
      params[:hgv_meta_identifier][:figures]&.delete_if do |_index, figure|
        !figure[:children] || !figure[:children][:graphic] || !figure[:children][:graphic][:attributes] || !figure[:children][:graphic][:attributes][:url] || figure[:children][:graphic][:attributes][:url].strip.empty?
      end

      # get rid of empty publication parts
      params[:hgv_meta_identifier][:publicationExtra]&.delete_if do |_index, extra|
        extra[:value].blank?
      end

      if params[:hgv_meta_identifier][:textDate]

        # get rid of empty (invalid) date items
        params[:hgv_meta_identifier][:textDate].delete_if do |_index, date|
          date[:c].empty? && date[:y].empty? && !date[:unknown]
        end

        params[:hgv_meta_identifier][:textDate].permit!
        # get rid of unnecessary date attribute @xml:id if there is only one date
        if params[:hgv_meta_identifier][:textDate].to_h.length == 1
          params[:hgv_meta_identifier][:textDate]['0'][:attributes][:id] = nil
        end
      end

      # get rid of empty certainties for mentioned dates (X, Y, Z)
      params[:hgv_meta_identifier]['mentionedDate']&.each_pair do |_index, date|
        unless date['children'] && date['children']['date'] && date['children']['date']['children'] && date['children']['date']['children']['certainty']
          next
        end

        date['children']['date']['children']['certainty'].each_pair do |certainty_index, certainty|
          if certainty['attributes'] && certainty['attributes']['relation'] && certainty['attributes']['relation'].empty?
            date['children']['date']['children']['certainty'].delete certainty_index
          end
        end
      end

    end
  end

  # Adds additional information to incoming post data (e.g. adds hgv formatted date string for each date records provided by the user)
  # Assumes that hgv metadata post data is passed in
  # Complements incoming form data for hash entries +:textDate+, +:mentionedDate+ and +provenance+
  # Side effect on params variable
  def complement_params
    if params[:hgv_meta_identifier]

      params[:hgv_meta_identifier][:textDate]&.each do |index, date| # for each textDate, i.e. X, Y, Z
        date[:id] = date[:attributes][:id]
        date.delete_if { |_k, v| !v.instance_of?(String) || v.empty? }
        params[:hgv_meta_identifier][:textDate][index] = HGVDate.hgvToEpidoc date
      end

      params[:hgv_meta_identifier][:mentionedDate]&.each do |_index, date|
        if date[:children] && date[:children][:date] && date[:children][:date][:attributes]
          date[:children][:date][:value] = HGVFormat.formatDateFromIsoParts(date[:children][:date][:attributes][:when], date[:children][:date][:attributes][:notBefore], date[:children][:date][:attributes][:notAfter], date[:certaintyPicker]) # cl: using date[:certaintyPicker] here is actually a hack
        end
      end

      if params[:hgv_meta_identifier][:provenance]
        hgv = HGVMetaIdentifier.new
        params.permit!
        hgv.populate_epidoc_attributes_from_attributes_hash params[:hgv_meta_identifier].to_h
        params[:hgv_meta_identifier][:origPlace] = HGVProvenance.format hgv.non_database_attribute[:provenance]

      else
        params[:hgv_meta_identifier][:origPlace] = 'unbekannt'
      end

    end
  end

  # Writes some helpful status information for the user, e.g. 'File update' plus some quick links to guide the user's subsequent actions
  # Side effect on #flash#, i.e. +flash[:notice]+
  def generate_flash_message
    flash[:notice] = 'File updated.'
    if %w[new editing].include? @identifier.publication.status
      flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
    end
  end

  # Saves user's comment on a save operation to the database
  # - *Args*  :
  #   - +comment+ → comment made by the user and passed in via post parameters
  #   - +commit_sha+ → hash string of the corresponding git commit
  # Writes to database
  # Side effect on +@comment+
  def save_comment(comment, commit_sha)
    if !comment.nil? && comment.strip != ''
      @comment = Comment.new({ git_hash: commit_sha, user_id: @current_user.id,
                               identifier_id: @identifier.id, publication_id: @identifier.publication_id, comment: comment, reason: 'commit' })
      @comment.save
    end
  end

  # Retrieves hgv identifier from database by id which it takes from the incoming post stream
  # Assumes that post data contains hgv identifier id
  # Side effect on +@identifier+
  def find_identifier
    @identifier = HGVMetaIdentifier.find(params[:id].to_s)
  end

  private

  def hgv_meta_identifier_params
    params.require(:hgv_meta_identifier).permit(:provenance, :origPlace, :mentionedDate, :textDate, :figures,
                                                :publicationExtra)
  end
end
