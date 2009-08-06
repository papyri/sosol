class GlossariesController < ApplicationController

   # FIXME: add a find_glossary method that uses Glossary.new({:publication_id => ???}) to populate @glossary, then call methods against it instead of Glossary.new (which uses canon)
  layout 'site'
  before_filter :authorize
  
  
  # GET /glossaries
  # GET /glossaries.xml
  def index
   @glossaries = Glossary.new.xml_to_entries()

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @glossaries }
    end
  end

  # GET /glossaries/1
  # GET /glossaries/1.xml
  def show
 
    @glossary = Glossary.new.find_item(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @glossary }
    end
  end

  # GET /glossaries/1/edit
  def edit
    @glossary = Glossary.new.find_item(params[:id])
  end

  # POST /glossaries
  # POST /glossaries.xml
  def create
    #TODO add new to xml
    #glossaries must exist...
    #add new entry 
    raise "Glossary needs parent publication"
    Glossary.new.add_entry_to_file(params[:glossary])
    redirect_to :action => 'index'
  end

  # PUT /glossaries/1
  # PUT /glossaries/1.xml
  def update
    raise "Glossary needs parent publication"
    Glossary.addEntry(params[:glossary])
  end

  # DELETE /glossaries/1
  # DELETE /glossaries/1.xml
  def destroy
    raise "Glossary needs parent publication"
    Glossary.new.delete_entry_in_file(params[:id])
    redirect_to :action => 'index'
  end
end
