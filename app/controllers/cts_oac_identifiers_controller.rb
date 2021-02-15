class CtsOacIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  
  def edit
    find_publication_and_identifier
    annotation_uri = params[:annotation_uri].to_s || @identifier[:annotation_uri]
    if (annotation_uri)
      @creator_uri = @identifier.make_creator_uri()
      annotation = @identifier.get_annotation(annotation_uri)
      if (annotation.nil?)
        flash[:error] = "Annotation #{annotation_uri} not found"
        redirect_to(:action => :preview,:publication_id => @publication.id, :id => @identifier.id) and return
      elsif (@identifier.get_creator(annotation) != @creator_uri && @publication.status != 'finalizing')
        flash[:error] = "You can only edit annotations you created"
        redirect_to(:action => :preview,:publication_id => @publication.id, :id => @identifier.id) and return
      else
        @identifier[:action] = 'update'
        params[:annotation_uri] = annotation_uri
        params[:annotation_title] = @identifier.get_title(annotation)
        params[:body_uri] = @identifier.get_body(annotation)
        index = 1
        targets = @identifier.get_targets(annotation)
        targets.each do |tgt|
          params["target_uri#{index}"] = tgt
          index = index+1
        end
        uri_parts =params[:target_uri1].split('/urn:cts:')
        urn = "urn:cts:#{uri_parts[1]}"
        src = uri_parts[0]
        urn.sub!(/^.*?urn:cts/,'urn:cts')
        urnObj = CTS::CTSLib.urnObj(urn)
        params[:target_urn] = "#{urnObj.getUrnWithoutPassage()}:#{urnObj.getPassage(1000)}"
        params[:collection] = @identifier.parentIdentifier.inventory
        params[:src] = src
        params[:valid_targets] = (1..targets.size).map { |i| "target_uri#{i}"}.join(",") 
      end
    else
      # we can't allow editing of the file as a whole because we
      # need to keep people from editing others annotations
      flash[:error] = "You must select an annotation to edit."
      redirect_to(:action => :preview,:publication_id => @publication.id, :id => @identifier.id) and return
    end  
  end
  
  def edit_or_create
    # create the OAC identifier if it doesn't exist
    find_publication
    @parent = @publication.identifiers.select{ | pubid | pubid.name == params[:version_id] }.first
    @identifier = OACIdentifier.find_from_parent(@publication,@parent)
    
    if @identifier.nil?
      @identifier = OACIdentifier.new_from_template(@publication,@parent)
      @creator_uri = @identifier.make_creator_uri()
      @identifier[:action] = 'append'
      render(:template => 'cts_oac_identifiers/edit') and return
    else
      @creator_uri = @identifier.make_creator_uri()
      @identifier[:action] = 'append'
      if params[:commit] == 'Append'
        # if the confirmed that they want to add a new annotation for this target, bring them to the 
        # apppend form
        render(:template => 'cts_oac_identifiers/edit') and return
      else
        # otherwise give the user the choice
        # if it already existed, then it may have existing annotations for the requested target
        # look for any targets which reference the citation urn (regardless of source repo)
        # including any with subreference pointers in this target
        possible_matches = @identifier.matching_targets("#{Regexp.quote(params[:target_urn])}\#?",@creator_uri)
        if possible_matches.size > 0
            render(:template => 'cts_oac_identifiers/edit_or_create',
                 :locals => {:matches => possible_matches})
        else     
          render(:template => 'cts_oac_identifiers/edit') and return
        end
      end
    end
    
  end
 
  def append
    find_publication_and_identifier
    # TODO validate input
    
    # accumulate target uris
    target_uris = []
    params[:valid_targets].split(',').each do |uri| 
      target_uris << params[uri] 
    end
    
    body_uri = params[:body_uri]
    title = params[:annotation_title]
    @creator_uri = @identifier.make_creator_uri()
    annotation_uri = @identifier.next_annotation_uri()
    @identifier.add_annotation(annotation_uri,target_uris,body_uri,title,@creator_uri,'Added Annotation')
    redirect_to(:action => :preview,
       :annotation_uri => annotation_uri, :publication_id => @publication.id, :id => @identifier.id) and return
  end
  
  def update 
    find_publication_and_identifier
    annotation_uri = params[:annotation_uri]
    @creator_uri = @identifier.make_creator_uri()
    annotation = @identifier.get_annotation(annotation_uri)
    if (annotation.nil?)
      Rails.logger.error("Updating invalid annotation uri #{annotation_uri}")
      flash[:error] = "Annotation #{annotation_uri} not found"
      redirect_to(:action => :preview,:publication_id => @publication.id, :id => @identifier.id) and return
    elsif (@identifier.get_creator(annotation) != @creator_uri && @publication.status != 'finalizing')
      Rails.logger.error("Updating unauthorized annotation uri #{annotation_uri}")
      flash[:error] = "You can only edit annotations you created"
      redirect_to(:action => :preview,:publication_id => @publication.id, :id => @identifier.id) and return
    end
    target_uris = []
    params[:valid_targets].split(',').each do |uri| 
      target_uris << params[uri] 
    end
    body_uri = params[:body_uri]
    title = params[:annotation_title]
    @identifier.update_annotation(annotation_uri,target_uris,body_uri,title,@creator_uri,"Updated Annotation #{annotation_uri}")
    redirect_to(:action => :preview,
       :annotation_uri => annotation_uri, :publication_id => @publication.id, :id => @identifier.id) and return
  end
  
  def delete_annotation 
    find_publication_and_identifier
    annotation_uri = params[:annotation_uri]
    @creator_uri = @identifier.make_creator_uri()
    annotation = @identifier.get_annotation(annotation_uri)
    if (annotation.nil?)
      Rails.logger.error("Deleting invalid annotation uri #{annotation_uri}")
      flash[:error] = "Annotation #{annotation_uri} not found"
      redirect_to(:action => :preview,:publication_id => @publication.id, :id => @identifier.id) and return
    elsif (@identifier.get_creator(annotation) != @creator_uri && @publication.status != 'finalizing')
      Rails.logger.error("Deleting unauthorized annotation uri #{annotation_uri}")
      flash[:error] = "You can only delete annotations you created"
      redirect_to(:action => :preview,:publication_id => @publication.id, :id => @identifier.id) and return
    end
    @identifier.delete_annotation(annotation_uri,"Deleted Annotation #{annotation_uri}")
    redirect_to(:action => :preview, :publication_id => @publication.id, :id => @identifier.id) and return
  end
  
  def preview
    find_identifier
    if (@identifier.publication.status != 'finalizing')
      params[:creator_uri] = @identifier.make_creator_uri()
    end
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
