class IdentifiersController < ApplicationController
  # def method_missing(method_name, *args)
  #   identifier = Identifier.find(params[:id])
  #   redirect_to :controller => identifier.class.to_s.pluralize.underscore, :action => method_name
  # end
  
  # GET /publications/1/xxx_identifiers/1/editxml
  def editxml
    find_identifier
    @identifier[:xml_content] = @identifier.xml_content
    render :template => 'identifiers/editxml'
  end
  
  # GET /publications/1/xxx_identifiers/1/history
  def history
    find_identifier
    @identifier.get_commits
    @identifier[:commits].each do |commit|
      if commit[:message].empty?
        commit[:message] = '(no commit message)'
      end
      commit[:url] = GITWEB_BASE_URL +
                     ["#{@identifier.publication.owner.repository.path.sub(/^#{REPOSITORY_ROOT}/,'db/git')}",
                      "a=commitdiff",
                      "h=#{commit[:id]}"].join(';')
    end
    render :template => 'identifiers/history'
  end
  
  # POST /identifiers
  def create
    @publication = Publication.find(params[:publication_id])
    identifier_type = params[:identifier_type].constantize
    
    @identifier = identifier_type.new_from_template(@publication)
    flash[:notice] = "File created."
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :editxml) and return
  end
  
  # PUT /publications/1/xxx_identifiers/1/updatexml
  def updatexml
    find_identifier
    # strip carriage returns
    xml_content = params[@identifier.class.to_s.underscore][:xml_content].gsub(/\r\n?/, "\n")
    @identifier.set_xml_content(xml_content,
                                params[:comment])
    flash[:notice] = "File updated."
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :editxml) and return
  end
end