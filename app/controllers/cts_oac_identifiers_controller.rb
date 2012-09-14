class CtsOacIdentifiersController < IdentifiersController
  layout SITE_LAYOUT
  before_filter :authorize
  
  def edit
    redirect_to :action =>"editxml",:id=>params[:id]
  end
  
  def edit_or_create
    # create the OAC identifier if it doesn't exist
    find_publication
    @parent = @publication.identifiers.select{ | pubid | pubid.name == params[:version_id] }.first
    @identifier = OACIdentifier.find_from_parent(@publication,@parent)
    @creator_uri = ActionController::Integration::Session.new.url_for(:host => SITE_USER_NAMESPACE, :controller => 'user', :action => 'show', :user_name => @publication.creator.name, :only_path => false)
    
    if @identifier.nil?
      @identifier = OACIdentifier.new_from_template(@publication,@parent)
    else
      if params[:commit] == 'Append'
        # if the confirmed that they want to add a new annotation for this target, bring them to the 
        # apppend form
        render(:template => 'cts_oac_identifiers/append') and return
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
          render(:template => 'cts_oac_identifiers/append')
        end
      end
    end
    
  end
 
  def append
    find_publication_and_identifier
    # TODO validate input
    
    # create the annotation uri 
    
    # accumulate target uris
    target_uris = []
    params[:valid_targets].split(',').each do |uri| 
       target_uris << params[uri] 
    end
    
    body_uri = params[:body_uri]
    title = params[:annotation_title]
    @creator_uri = ActionController::Integration::Session.new.url_for(:host => SITE_USER_NAMESPACE, :controller => 'user', :action => 'show', :user_name => @publication.creator.name, :only_path => false)
    annotation_uri = @identifier.next_annotation_uri();
    @identifier.add_annotation(annotation_uri,target_uris,body_uri,title,@creator_uri,'Added Annotation')
    redirect_to(:action => :preview,
       :annotation_uri => annotation_uri, :publication_id => @publication.id, :id => @identifier.id) and return
  end
  
    
  def preview
    find_identifier
    @identifier[:html_preview] = @identifier.preview(params)
  end
  
  protected
    def find_identifier
      @identifier = OACIdentifier.find(params[:id])
    end
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id])
      find_identifier
    end
    
     def find_publication
      @publication = Publication.find(params[:publication_id])
    end
end
