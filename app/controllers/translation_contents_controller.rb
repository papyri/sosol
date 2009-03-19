class TranslationContentsController < ApplicationController
 
 
 
 
 
  # GET /translation_contents
  # GET /translation_contents.xml
  def index
    @translation_contents = TranslationContent.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @translation_contents }
    end
  end

  # GET /translation_contents/1
  # GET /translation_contents/1.xml
  def show
    @translation_content = TranslationContent.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @translation_content }
    end
  end

  # GET /translation_contents/new
  # GET /translation_contents/new.xml
  def new
    @translation_content = TranslationContent.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @translation_content }
    end
  end

  # GET /translation_contents/1/edit
  def edit
    @translation_content = TranslationContent.find(params[:id])
  end

  # POST /translation_contents
  # POST /translation_contents.xml
  def create
    #@translation_content = TranslationContent.new(params[:translation_content])
    
    @translation_content = TranslationContent.new()
    @translation_content.language = params[:language]


    respond_to do |format|
      if @translation_content.save
        translation = Translation.find(params[:translation_id])
    	translation.translation_contents << @translation_content
        flash[:notice] = 'TranslationContent was successfully created.'
        #go to edit of item
        #render :controller => "translations", :action => "edit", :id => translation.id
        
        format.html { render :controller => "translations", :action => "edit", :id => translation.id }
        
        #format.html { redirect_to(@translation_content) }
        format.xml  { render :xml => @translation_content, :status => :created, :location => @translation_content }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @translation_content.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /translation_contents/1
  # PUT /translation_contents/1.xml
  def update
    @translation_content = TranslationContent.find(params[:id])

    respond_to do |format|
      if @translation_content.update_attributes(params[:translation_content])
        flash[:notice] = 'TranslationContent was successfully updated.'
        format.html { redirect_to(@translation_content) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @translation_content.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /translation_contents/1
  # DELETE /translation_contents/1.xml
  def destroy
    @translation_content = TranslationContent.find(params[:id])
    @translation_content.destroy

    respond_to do |format|
      format.html { redirect_to(translation_contents_url) }
      format.xml  { head :ok }
    end
  end
end
