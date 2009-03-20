class TranslationsController < ApplicationController

  layout 'site'
  

  def epidoc_to_translation_contents
    @translation = Translation.find(params[:id])
    @translation.PutEpidocToTranslationContents(true)
    @translation.save
    redirect_to :controller => "translations", :action => "edit", :id => @translation.id
  end


  def translation_contents_to_epidoc
    @translation = Translation.find(params[:id])
    @translation.PutTranslationContentsToEpidoc()
    @translation.save
    redirect_to :controller => "translations", :action => "edit", :id => @translation.id
  end

  # ask user which language they want to add
  def add_new_translation_content
 	
    @translation = Translation.find(params[:id])
    langs = @translation.GetLanguagesInTranslationContents();
    @languages = {"Franz&#195;&#182;sisch" => "fr", "Englisch" => "en", "Deutsch" => "de", "Italienisch" => "it", "Spanisch" => "es", "Latein" => "la", "Griechisch" => "el" }
    #remove existing langs from the options
    langs.each do |lang|       
      @languages.each do |l|        
        if l[1] == lang
          @languages.delete(l[0])          
        end
      end
    end  
  end
 
  # adds the new language to the translation content
  def add_new_translation_language
    @translation = Translation.find(params[:id])
    @translation.AddNewLanguageToTranslationContents(params[:language])
   
       respond_to do |format|
      if @translation.save
        flash[:notice] = 'New language successfully added to translation.'
        format.html { redirect_to(@translation) }
       # format.xml  { render :xml => @translation, :status => :created, :location => @translation }
      #else
      #  format.html { render :action => "new" }
      #  format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
      end
    end
    
  end


  # GET /translations
  # GET /translations.xml
  def index
    @translations = Translation.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @translations }
    end
  end

  # GET /translations/1
  # GET /translations/1.xml
  def show
    @translation = Translation.find(params[:id])
   @translation.GetTranslationsFromTranslationContents()
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @translation }
    end
  end

  # GET /translations/new
  # GET /translations/new.xml
  def new
    @translation = Translation.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @translation }
    end
  end

  # GET /translations/1/edit
  def edit
    @translation = Translation.find(params[:id])
  end

  # POST /translations
  # POST /translations.xml
  def create
    @translation = Translation.new(params[:translation])

    respond_to do |format|
      if @translation.save
        flash[:notice] = 'Translation was successfully created.'
        format.html { redirect_to(@translation) }
        format.xml  { render :xml => @translation, :status => :created, :location => @translation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /translations/1
  # PUT /translations/1.xml
  def update
    @translation = Translation.find(params[:id])
    #TODO find the param hash for epidoc
   hackTrans = Translation.new(params[:translation])
   @translation.epidoc = hackTrans.epidoc
   #save the changes in the translation contents
langReg = Regexp.new('(translation_content_)(..)(_content)')

params.each do |p|
  langMatch = langReg.match(p[0])
  if langMatch
    #find the corresponding contents
    @translation.translation_contents.each do |tc|
      if tc.language == langMatch[0].split('_')[2]
        tc.content = p[1]
        tc.save
      end
    end
#  
#   tc = TranslationContent.new()
#   tc.content =  p[1];
#   tc.language = langMatch[0].split('_')[2]
#   
#   @translation.PutTranslationToXML(tc)
  # @translation.epidoc = @translation.epidoc + "^^^" + tc.language + "^^^"
  end

end


    respond_to do |format|
     # if @translation.update_attributes(params[:translation])
      if @translation.save
        flash[:notice] = 'Translation was successfully updated.'
        format.html { redirect_to(@translation) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /translations/1
  # DELETE /translations/1.xml
  def destroy
    @translation = Translation.find(params[:id])
    @translation.destroy

    respond_to do |format|
      format.html { redirect_to(translations_url) }
      format.xml  { head :ok }
    end
  end
end
