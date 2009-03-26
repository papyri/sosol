class TranslationsController < ApplicationController

  layout 'site'
  
    
  def finalize
  	@translation = Translation.find(params[:id])
  	
  	TranslationMailer.deliver_final_translation("ok@mybit.net", @translation.epidoc)
 
  end
  
   def submit
 
   @translation = Translation.find(params[:id])
 
   if (params[:comment] == nil || params[:comment] == "")
     flash[:notice] = 'You must provide reasoning.'
     redirect_to :action => "review_for_submit", :id => params[:id]
   else
	 
	   comment = Comment.new()
	   comment.article_id = params[:id]
	   comment.text = params[:comment]
	   comment.user_id = @current_user.id
	   comment.reason = "submit"
	   comment.save()
	   
	   @translation.article.comments << comment
	   @translation.article.status = "submitted"
	   @translation.article.save()  #need to save here?
	   @translation.save()
	   
	   flash[:notice] = 'Translation has been submitted.'
	   redirect_to  url_for(@translation.article.master_article)
   end   
 end
  
  
   def review_for_submit
   	@translation = Translation.find(params[:id])
 
   end
 
  def ask_for_epidoc_file
      @translation = Translation.find(params[:id])
  end
  
  def load_epidoc_file
    @translation = Translation.find(params[:id])
    @translation.load_epidoc_from_file(params[:filename])
    @translation.save
    redirect_to :controller => "translations", :action => "edit", :id => @translation.id
  end

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
   
   
    #  if @translation.save
   	#	redirect_to :controller => "translations", :action => "edit", :id => @translation.id
   #	end
   	
       respond_to do |format|
      if @translation.save
        flash[:notice] = 'New language successfully added to translation.'
        format.html { redirect_to( edit_translation_path @translation) }
        
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
