# frozen_string_literal: true

class OacIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_action :authorize

  def edit
    find_publication_and_identifier
    if params[:annotation_uri]
      annotation = @identifier.get_annotation(params[:annotation_uri])
      unless annotation.nil?
        target_uris = @identifier.get_targets(annotation)
        Rails.logger.info("Found #{target_uris.inspect}")
        if target_uris.grep(%r{^.*?/urn:cts}).size == target_uris.size
          redirect_to controller: 'cts_oac_identifiers', action: 'edit',
                      annotation_uri: params[:annotation_uri] and return
        end
      end
    else
      # we can't allow editing of the file as a whole because we
      # need to keep people from editing others annotations
      if @publication.status == 'editing' || @publication.status == 'finalizing'
        flash[:notice] = 'Select an annotation to edit.'
      end
      redirect_to(action: :preview, publication_id: @publication.id, id: @identifier.id) and return
    end
  end

  def preview
    find_identifier
    params[:creator_uri] = @identifier.make_creator_uri if @identifier.publication.status != 'finalizing'
    @identifier_html_preview = @identifier.preview(params)
    @identifier[:annotation_uri] = params[:annotation_uri]
  end

  protected

  def find_identifier
    @identifier = OACIdentifier.find(params[:id].to_s)
  end

  def find_publication_and_identifier
    @publication = Publication.find(params[:publication_id].to_s)
    find_identifier
  end

  def find_publication
    @publication = Publication.find(params[:publication_id].to_s)
  end
end
