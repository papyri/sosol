class TranslationsController < ApplicationController

  layout 'site'
  
    
  def review_for_finalize
  	@translation = Translation.find(params[:id])
  	@article = @translation.article
  end
    
  def finalize
  
  	@translation = Translation.find(params[:id])
  	#TranslationMailer.deliver_final_translation(  , @translation.epidoc)
  	TranslationMailer.deliver_final_translation("ok@mybit.net", @translation.epidoc)
 		#TODO COMMENTED OUT FOR TESTING
 		#@translation.article.status = "finalized"
 		#@translation.article.save
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
  
  def edit_epidoc
  	@translation = Translation.find(params[:id])
  	#check if epidoc ok
  	if !@translation.translations_to_xml_ok
  		#they changed the translations and messed up the xml so the xml may not be what they want
  		#flash[:notice] = "The translation changes are inconsisent with the xml!"
  	else
  		#flash[:notice] = "OK"
  	end
  end
  
  def ask_for_epidoc_number
  	@translation = Translation.find(params[:id])
  end
  
  def load_epidoc_from_number
  
  	filename = get_translations_dir + params[:epidoc_number].to_s + ".xml"  	  
  	#TODO add error checking
  	@translation = Translation.find(params[:id])
  	@translation.load_epidoc_from_file(filename)
  	@translation.save
  	redirect_to :controller => "translations", :action => "edit_contents", :id => @translation.id
  end
    
  def edit_contents
  	@translation = Translation.find(params[:id])  	
  	#check if contents ok
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
    @languages = {"French" => "fr", "English" => "en", "German" => "de", "Italien" => "it", "Spanish" => "es", "Latin" => "la", "Greek" => "el" }
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
        format.html { redirect_to :controller => "translations", :action => "edit_contents", :id => @translation.id }
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
    @translation.xml_to_translations_ok = true
    @translation.translations_to_xml_ok = true

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
		

		flash[:notice] = " "#so the += will work, otherwise error with + nil
#		if params[:edit_epidoc] == "true"
#		  redirect_to(@translation)
#		end
		  
		@translation = Translation.find(params[:id])
		
		#incomingTranslation = Translation.new(params[:translation])		
		
		#if @translation.xml_to_translations_ok && @translation.translations_to_xml_ok 
		#	doOverwrite = true
		#end
		
		forceOverwrite = false
		if params[:commit] == "Save Changes & Overwite XML" || params[:commit] == "Save Changes & Overwite Translations"
		  forceOverwrite = true 
		end
		
		#doOverwrite = params[:commit] == "Save Changes & Overwite XML"
		
		#doOverwrite = params[:commit] == "Save Changes & Overwite Translations"
		#lots of work to do here,
		#editing options are:
		#  1. editing the XML epidoc
		#			check if valid
		#				if valid, update translation texts
		#				if invalid, do what ? save but don't update text since we can't (and we don't want to wipe them out?)
		#
		#  2. editing the translation texts
		#				check if can transform into epidoc (ie we add them to the existing epidoc, but don't change the other data in the epidoc)
		#				if can transform then save the epidoc
		
		#what to do if we end up with one form (epidoc or texts) that cannot be transformed to the other? we can save both but how do we decide which has presidence?
		
		
			
		#separate the epidoc content that just came in
	#	editiedTranslation = Translation.new(params[:translation])
	#	@translation.epidoc = editiedTranslation.epidoc
	
	  #remember the original translation 
	  #TODO what is Ruby default method for coping, deep or shallow?
		#bakTranslation = @translation
	
	
	
	
	
	#-----EDIT XML-----EDIT XML-----EDIT XML-----EDIT XML-----EDIT XML-----EDIT XML-----EDIT XML-----EDIT XML-----
		if  params[:edit_epidoc] == "true"  	
		  #the xml rules, let them put whatever crap they want in it?, but lets remember that it is not convertable & not allow them to commit it? (ie it would break the reading of it later?)

		  #need warn if epidoc fails or is not transferable!

		  #separate the epidoc content that just came in
			@translation.epidoc = Translation.new(params[:translation]).epidoc

		  #update contents using the new epidoc		  		  
		  if (@translation.xml_to_translations_ok && @translation.translations_to_xml_ok) || forceOverwrite #forcing overwrite does not make sense if we cannot parse the new xml, really just means to try to overwrite
		  	#try to convert
				@translation.xml_to_translations_ok = @translation.PutEpidocToTranslationContents(true)	#returns false if translations cannot be pulled from epidoc (contents are not altered)
				
				if @translation.xml_to_translations_ok
					@translation.save
					flash[:notice] = "XML saved, translations updated."
					redirect_to :controller => "translations", :action => "edit_epidoc", :id => @translation.id
					return		    
				else
					#epidoc to translations failed, warn user		    
					#reload edit page with failed data
					
					#@translation.xml_to_translations_ok = false
					#note we still save to keep the epidoc, the PutEpidocToTranslationContents will not save if it fails
					@translation.save		    
					flash[:notice] = "XML failed to convert to translations."
					redirect_to :controller => "translations", :action => "edit_epidoc", :id => @translation.id
					return
				end
			
			else
				
				@translation.xml_to_translations_ok = false #since we did not try
				@translation.save
				flash[:notice] = "XML saved."
				redirect_to :controller => "translations", :action => "edit_epidoc", :id => @translation.id
				return
		  end
		#=====EDIT XML=====EDIT XML=====EDIT XML=====EDIT XML=====EDIT XML=====EDIT XML=====EDIT XML=====EDIT XML=====		  
		  
		#-----EDIT CONTENTS-----EDIT CONTENTS-----EDIT CONTENTS-----EDIT CONTENTS-----EDIT CONTENTS-----EDIT CONTENTS-----EDIT CONTENTS-----EDIT CONTENTS-----
		elsif params[:edit_contents] == "true"
									
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
							#TODO add warninig if save fails
						end
					end
				end
			end
			
			if (@translation.xml_to_translations_ok && @translation.translations_to_xml_ok) || forceOverwrite
				
				#see if we can convert to xml
				begin
				#try to write into existing xml
					@translation.translations_to_xml_ok = @translation.PutTranslationsToEpidoc(@translation.translation_contents, false)
				rescue XmlCreationError 
				  begin
						if forceOverwrite						  
							#writing to existing xml failed, so check if we want to wipe it out and start new (note that this drastic option will only happen if we have failed to add to existing xml)
							@translation.translations_to_xml_ok = @translation.PutTranslationsToEpidoc(@translation.translation_contents, true)
						end
					rescue
				  	flash[:notice] += $!.message
				  	@translation.translations_to_xml_ok = false #??
				  end
				end
				
				if @translation.translations_to_xml_ok
					#since we made the xml, then we assuem it is ok too
					@translation.xml_to_translations_ok = true
					@translation.save
					flash[:notice] += "Translations saved, XML updated"
					redirect_to :controller => "translations", :action => "edit_contents", :id => @translation.id
					return				
				else
					#failed
					#@translation.translations_to_xml_ok = false
					#add error message
					flash[:notice] += "Translations failed to convert to XML"
					redirect_to :controller => "translations", :action => "edit_contents", :id => @translation.id
					return
				end
			else
				#we have already saved the changes, so just redirect here
				flash[:notice] += "Translations saved"
				redirect_to :controller => "translations", :action => "edit_contents", :id => @translation.id
				return			
			end
			#=====EDIT CONTENTS=====EDIT CONTENTS=====EDIT CONTENTS=====EDIT CONTENTS=====EDIT CONTENTS=====EDIT CONTENTS=====EDIT CONTENTS=====EDIT CONTENTS=====
		
		#else
		  #editing both parts
		  		
		end
		
		
#    respond_to do |format|
     # if @translation.update_attributes(params[:translation])
#      if @translation.save
#        flash[:notice] = 'Translation was successfully updated.'
#        format.html { render :action => "edit" }# redirect_to(@translation) } # or render :action => "edit"
#        format.xml  { head :ok }
#      else
#        format.html { render :action => "edit" }
#        format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
#      end
#    end
    
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
