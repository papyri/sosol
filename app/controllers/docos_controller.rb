class DocosController < ApplicationController
  layout 'site'
  #caches_page :documentation
  # GET /docos
  # GET /docos.xml
  def index
    @docotype = params[:docotype]
    @docos = Doco.find(:all, :conditions => {:docotype => params[:docotype]}, :order => "category, line")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @docos }
    end
  end

  # GET /docos/1
  # GET /docos/1.xml
  def show
    @doco = Doco.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @doco }
    end
  end

  # GET /docos/new
  # GET /docos/new.xml
  def new
    if params[:id] == "blank"
      @doco = Doco.new
    else
      @fillin = Doco.find(params[:id])
      @doco = Doco.new
      @doco.category = @fillin.category
      @doco.line = @fillin.line
      @doco.preview = @fillin.preview
      @doco.description = @fillin.description
      @doco.note = @fillin.note
      @doco.xml = @fillin.xml
      @doco.docotype = @fillin.docotype
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @doco }
    end
  end

  # GET /docos/1/edit
  def edit
    @doco = Doco.find(params[:id])
  end

  # POST /docos
  # POST /docos.xml
  def create
    @doco = Doco.new(params[:doco]) #to have something to send to template if an error in edit_input
    edit_check = edit_input('new')
    
    if edit_check == 'passed edits'
      @doco = Doco.new(params[:doco]) #create for save with param values after edit_input has filled in/tweaked
      respond_to do |format|
        if @doco.save
          flash[:notice] = 'Doco was successfully created.'
          format.html { redirect_to(@doco) }
          format.xml  { render :xml => @doco, :status => :created, :location => @doco }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @doco.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /docos/1
  # PUT /docos/1.xml
  def update
    @doco = Doco.find(params[:id])
    edit_check = edit_input('edit')
    
    if edit_check == 'passed edits'
    
      respond_to do |format|
        if @doco.update_attributes(params[:doco])
          flash[:notice] = 'Doco was successfully updated.'
          #format.html { redirect_to(@doco) }
          format.html { redirect_to(docos_url(:docotype => @doco.docotype)) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @doco.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /docos/1
  # DELETE /docos/1.xml
  def destroy
    @doco = Doco.find(params[:id])
    @doco.destroy

    respond_to do |format|
      format.html { redirect_to(docos_url(:docotype => @doco.docotype)) }
      format.xml  { head :ok }
    end
  end
  
  def build
    redirect_to(documentation_url(:docotype => params[:docotype]))
  end
  
  def documentation
    @docotype = params[:docotype]
  end
  
  private

  def edit_input(where_return)
    chk_docotype = params[:doco][:docotype]
    if params[:volume_number] != nil #if selector has values, use it to determine URL
      identifier_class = params[:IdentifierClass]
      collection = params["#{identifier_class}CollectionSelect"]
      volume = params[:volume_number]
      document = params[:document_number]
      
      if volume == 'Volume Number'
        volume = ''
      end
      
      if (document == 'Document Number') || document.blank?
        flash.now[:error] = 'Error: you must specify a document number in the selector'
        #redirect_to edit_doco_path
        render :template => "docos/#{where_return}"
        return "error"
      end
      
      if identifier_class == 'DDBIdentifier'
        document_path = [collection.downcase, volume, document].join(';')
      elsif identifier_class == 'HGVIdentifier'
        collection = collection.tr(' ', '_')
        if volume.empty?
          document_path = [collection, document].join('_')
        else
          document_path = [collection, volume, document].join('_')
        end
      end
      
      #set the url to save to the first identifer returned
      params[:doco][:urldisplay] = [collection.downcase, volume, document].join(';')

      namespace = identifier_class.constantize::IDENTIFIER_NAMESPACE
      
      identifier = [NumbersRDF::NAMESPACE_IDENTIFIER, namespace, document_path].join('/')
      
      if identifier_class == 'HGVIdentifier'
        related_identifiers = NumbersRDF::NumbersHelper.collection_identifier_to_identifiers(identifier)
      else
        related_identifiers = NumbersRDF::NumbersHelper.identifier_to_identifiers(identifier)
      end
      
      if related_identifiers.nil? # nil is the default returned when do not get a real match
        flash.now[:error] = "Error: '#{identifier}' is probably not valid because no related identifiers can be found - try a different selector or user input URL"
        #redirect_to edit_doco_path
        render :template => "docos/#{where_return}"
        return "error"
      end
      #set the url to save to the first identifer returned used for test below and error message below
      params[:doco][:url] = related_identifiers.first
      params[:save_url] = ''
    else #selector  was not used so check if user changed the value using the input field
      if params[:save_url] != params[:doco][:url] #url changed by user so need to update display value
        if params[:doco][:url].strip.blank? #user blanked it out
          params[:doco][:urldisplay] = ""
          params[:save_url] = params[:doco][:url] #to keep logic below from trying to validate a blank
        else
          if params[:doco][:url].match(/^(papyri.info)\/(ddbdp|hgv)\/[a-z0-9\;]+$/) == nil
            flash.now[:error] = "Error: '#{params[:doco][:url].downcase}' is not in the correct input format - use either 'papyri.info/ddbdp/bgu;1;154' or 'papyri.info/hgv/80456' format"
            @doco.url = params[:doco][:url].downcase
            #redirect_to edit_doco_path
            render :template => "docos/#{where_return}"
            return "error"
          else
            if params[:doco][:url].include?("/hgv")
              params[:doco][:urldisplay] = params[:doco][:url].sub(/^papyri.info\/hgv\//, '')
            else
              params[:doco][:urldisplay] = params[:doco][:url].sub(/^papyri.info\/ddbdp\//, '')
            end
          end
        end
      end
    end
    
    if params[:save_url] != params[:doco][:url] #url changed by selector or user so need to validate, otherwise just save again
      # test the url from selector or the url entered by user to verify gets valid PN link
      test_url = NumbersRDF::NumbersHelper.identifier_to_url(params[:doco][:url].downcase)
      
      if test_url == "http://papyri.info" # the default returned when do not get a real match
        flash.now[:error] = "Error: '#{params[:doco][:url].downcase}' is not a valid PN URL - try a different selector class or correct user input format"
        @doco.url = params[:doco][:url].downcase
        #redirect_to edit_doco_path
        render :template => "docos/#{where_return}"
        return "error"
      else
        params[:doco][:url] = test_url 
      end
    end
    
    if params[:leiden_xml_radio] == "xml"  # XML to Leiden radio button clicked
      if params[:doco][:xml].blank?
        @doco.xml = params[:doco][:xml]
        @doco.leiden = params[:doco][:leiden]
        flash.now[:error] = "Error: you must supply XML when 'XML to Leiden' radio button clicked"
        #redirect_to edit_doco_path
        render :template => "docos/#{where_return}"
        return "error"
      else
        
        begin
          if chk_docotype == 'text'
            #xml must be wrapped in ab tags to parse correctly in xsugar grammar
            xml2conv = "<ab>" + params[:doco][:xml] + "</ab>"
            leidenback = Leiden.xml_leiden_plus(xml2conv)
          else #translation
            xml2conv = params[:doco][:xml]
            leidenback = TranslationLeiden.xml_to_translation_leiden(xml2conv)
          end
          params[:doco][:leiden] = leidenback
        rescue RXSugar::XMLParseError => parse_error
          @doco.leiden = params[:doco][:leiden]
          @doco.xml = params[:doco][:xml]
          #insert **ERROR** into content to help user find it - subtract 1 for offset from 0
          parse_error.content.insert((parse_error.column-1), "**ERROR**")
          flash.now[:error] = "Error at column #{parse_error.column} #{CGI.escapeHTML(parse_error.content)}"
          render :template => "docos/#{where_return}"
          return "error"
        end
      end
    else # Leiden to XML radio button clicked
      if params[:doco][:leiden].blank?
        @doco.xml = params[:doco][:xml]
        @doco.leiden = params[:doco][:leiden]
        flash.now[:error] = "Error: you must supply Leiden when 'Leiden to XML' radio button clicked"
        #redirect_to edit_doco_path
        render :template => "docos/#{where_return}"
        return "error"
      else
        
        leiden2conv = params[:doco][:leiden]
        begin
          if chk_docotype == 'text'
            xmlback = Leiden.leiden_plus_xml(leiden2conv)
          else #translation
            xmlback = TranslationLeiden.translation_leiden_to_xml(leiden2conv)
          end
          params[:doco][:xml] = "#{xmlback}"
        rescue RXSugar::NonXMLParseError => parse_error
          @doco.xml = params[:doco][:xml]
          @doco.leiden = params[:doco][:leiden]
          #insert **ERROR** into content to help user find it - subtract 1 for offset from 0
          parse_error.content.insert((parse_error.column-1), "**ERROR**")
          flash.now[:error] = "Error at column #{parse_error.column} #{CGI.escapeHTML(parse_error.content)}" 
          render :template => "docos/#{where_return}"
          return "error"
        end
      end
    end
    return "passed edits"
  end
  
end
