class TranscriptionsController < ApplicationController
  
  layout 'site'
  
  
  # GET /transcriptions
  # GET /transcriptions.xml
  def index
    @transcriptions = Transcription.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @transcriptions }
    end
  end

  # GET /transcriptions/1
  # GET /transcriptions/1.xml
  def show
    @transcription = Transcription.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @transcription }
    end
  end

  # GET /transcriptions/new
  # GET /transcriptions/new.xml
  def new
    @transcription = Transcription.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @transcription }
    end
  end

  # GET /transcriptions/1/edit
  def edit
    @transcription = Transcription.find(params[:id])
  end

  # POST /transcriptions
  # POST /transcriptions.xml
  def create
    @transcription = Transcription.new(params[:transcription])

    respond_to do |format|
      if @transcription.save
        flash[:notice] = 'Transcription was successfully created.'
        format.html { redirect_to(@transcription) }
        format.xml  { render :xml => @transcription, :status => :created, :location => @transcription }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @transcription.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /transcriptions/1
  # PUT /transcriptions/1.xml
  def update
    @transcription = Transcription.find(params[:id])

    respond_to do |format|
      if @transcription.update_attributes(params[:transcription])
        flash[:notice] = 'Transcription was successfully updated.'
        format.html { redirect_to(@transcription) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @transcription.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /transcriptions/1
  # DELETE /transcriptions/1.xml
  def destroy
    @transcription = Transcription.find(params[:id])
    @transcription.destroy

    respond_to do |format|
      format.html { redirect_to(transcriptions_url) }
      format.xml  { head :ok }
    end
  end
end
