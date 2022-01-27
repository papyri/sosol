# frozen_string_literal: true

class HgvTransGlossariesController < ApplicationController
  # FIXME: add a find_hgv_trans_glossary method that uses HGVTransGlossary.new({:publication_id => ???}) to populate @hgv_trans_glossary, then call methods against it instead of HGVTransGlossary.new (which uses canon)
  # layout 'site'
  before_action :authorize

  # GET /hgv_trans_glossaries
  # GET /hgv_trans_glossaries.xml
  def index
    @glossaries = HGVTransGlossary.new.xml_to_entries

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @glossaries }
    end
  end

  # GET /hgv_trans_glossaries/1
  # GET /hgv_trans_glossaries/1.xml
  def show
    @glossary = HGVTransGlossary.new.find_item(params[:id].to_s)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @glossary }
    end
  end

  # GET /hgv_trans_glossaries/1/edit
  def edit
    @entry = HGVTransGlossary.new.find_item(params[:id].to_s)
    @possible_langs = HGVTransGlossary.lang_codes
    @is_editor_view = true
  end

  # POST /hgv_trans_glossaries
  # POST /hgv_trans_glossaries.xml
  def create
    # TODO: add new to xml
    # hgv_trans_glossaries must exist...
    # add new entry
    raise 'HGVTransGlossary needs parent publication'
    HGVTransGlossary.new.add_entry_to_file(params[:hgv_trans_glossary].to_s)
    redirect_to action: 'index'
  end

  # PUT /hgv_trans_glossaries/1
  # PUT /hgv_trans_glossaries/1.xml
  def update
    raise 'HGVTransGlossary needs parent publication'
    HGVTransGlossary.addEntry(params[:hgv_trans_glossary].to_s)
  end

  # DELETE /hgv_trans_glossaries/1
  # DELETE /hgv_trans_glossaries/1.xml
  def destroy
    raise 'HGVTransGlossary needs parent publication'
    HGVTransGlossary.new.delete_entry_in_file(params[:id].to_s)
    redirect_to action: 'index'
  end
end
