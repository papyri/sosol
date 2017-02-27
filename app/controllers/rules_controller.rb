class RulesController < ApplicationController
  
  #layout "site"
  before_filter :authorize
  
  # GET /rules
  # GET /rules.xml
  def index
    @rules = Rule.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rules }
    end
  end

  # GET /rules/1
  # GET /rules/1.xml
  def show
    @rule = Rule.find(params[:id].to_s)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @rule }
    end
  end

  # GET /rules/new
  # GET /rules/new.xml
  def new
    @rule = Rule.new
    @rule.decree_id = params[:decree_id].to_s
    @decree = Decree.find(params[:decree_id].to_s)
   

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @rule }
    end
  end

  # GET /rules/1/edit
  def edit
    @rule = Rule.find(params[:id].to_s)
  end

  # POST /rules
  # POST /rules.xml
  def create
    @rule = Rule.new(params[:rule])
    Rails.logger.info("Rule = #{@rule}")

    if @rule.save
      decree = Decree.find(@rule.decree_id)
      decree.rules << @rule
      decree.save
      
      flash[:notice] = 'Rule was successfully created.'
      redirect_to :controller => "boards", :action => "edit", :id => decree.board_id
    end
  end

  # PUT /rules/1
  # PUT /rules/1.xml
  def update
    @rule = Rule.find(params[:id].to_s)

    respond_to do |format|
      if @rule.update_attributes(params[:rule])
        flash[:notice] = 'Rule was successfully updated.'
        
        format.html { redirect_to :controller => "boards", :action => "edit", :id => @rule.decree.board_id }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @rule.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /rules/1
  # DELETE /rules/1.xml
  def destroy
    @rule = Rule.find(params[:id].to_s)
    @rule.destroy

    respond_to do |format|
      format.html { redirect_to :controller => "boards", :action => "edit", :id => @rule.decree.board_id }
      format.xml  { head :ok }
    end
  end
end
