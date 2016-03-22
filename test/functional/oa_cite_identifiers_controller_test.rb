require 'test_helper'

class OaCiteIdentifiersControllerTest < ActionController::TestCase

  def setup 
    @user = FactoryGirl.create(:user)
    @user2 = FactoryGirl.create(:user)
    @request.session[:user_id] = @user.id
    @publication = FactoryGirl.create(:publication, :owner => @user, :creator => @user, :status => "new")
    @publication.branch_from_master

    # use a mock Google agent so test doesn't depend upon live google doc
    # test document should produce 9 annotations (from 6 entries in the spreadsheet)
    @client = stub("googless")
    @client.stubs(:get_content).returns(File.read(File.join(File.dirname(__FILE__), '../unit/data', 'google1.xml')))
    @client.stubs(:get_transformation).returns("/data/xslt/cite/gs_to_oa_cite.xsl")
    AgentHelper.stubs(:get_client).returns(@client)
    
  end

  def teardown
    @publication.destroy
    @user.destroy
    @user2.destroy
  end

  test "should get import" do
    get :import
    assert_response :success
  end

  test "should get import_update" do
    init_value = ["https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"]
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
    # TODO we need an identifier
    get :import_update, :id => @identifier.id.to_s
    assert_response :success
  end

  test "should get edit view without edit links" do
    init_value = ["https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"]
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
    get :edit, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
    assert_response :success
    puts @response.body
    assert_select 'div.oa_cite_annotation' do 
      # we shouldn't have any edit buttons in this view because the annotations are from an external agent
      assert_select 'div.edit_links>a', 0
    end
    assert_select 'div.oa_cite_annotation', 9
  end

  test "should get edit view with edit links" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @identifier.create_annotation("http://test.host/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1")
    get :edit, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
    puts @response.body
    assert_response :success
    assert_select 'div.oa_cite_annotation', 1
    assert_select 'div.oa_cite_annotation>div.edit_links>a', 1
  end


  test "edit with annotation_uri" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @identifier.create_annotation("http://localhost/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1")
    get :edit, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s, :annotation_uri => "http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1"
    assert_redirected_to( "http://localhost/annotation-editor/perseids-annotate.xhtml?uri=http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/%231&lang=LANG&doc=#{@identifier.id.to_s}")
  end

  test "should get editxml view" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @identifier.create_annotation("http://localhost/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1")
    get :editxml, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
    assert_response :success
    assert_select 'textarea#oa_cite_identifier_xml_content', 1
  end

  test "should process delete annotation" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @identifier.create_annotation("http://localhost/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1")
    post :delete_annotation, :publication_id => @identifier.publication.id.to_s,  :id => @identifier.id.to_s, :annotation_uri => "http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1"
    assert_equal "Annotation Deleted", flash[:notice]
    assert_redirected_to edit_publication_oa_cite_identifier_path( @identifier.publication, @identifier ) 
    post :delete_annotation, :publication_id => @identifier.publication.id.to_s,  :id => @identifier.id.to_s, :annotation_uri => "http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1"
    assert_equal "Annotation http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1 not found", flash[:error]
    assert_redirected_to preview_publication_oa_cite_identifier_path( @identifier.publication, @identifier )
  end

  test "enforce ownership on delete annotation" do
    @identifier = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
    @identifier.create_annotation("http://localhost/cts/getpassage/1/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1")
    @request.session[:user_id] = @user2.id
    post :delete_annotation, :publication_id => @identifier.publication.id.to_s,  :id => @identifier.id.to_s, :annotation_uri => "http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1"
    assert_equal "Operation not permitted.", flash[:error]
    assert_redirected_to( dashboard_url )
  end

  test "create" do 
  end

  test "enforce ownership on create" do 
  end

  test "edit_or_create should create a new annotation document" do
  end 

  test "edit_or_create should raise error creating a duplicate annotation document" do
  end 

  test "edit_or_create should redirect to append" do
  end 

  test "enforce ownership on edit_or_create" do 
  end

  test "append_annotation should update the document" do
  end

  test "enforce_ownership on append_annotation" do
  end

  test "update_from_agent" do
  end

  test "enforce_ownership on update_from_agent" do
  end

  test "preview" do
  end

  test "convert with create" do 
  end

  test "enforce ownership on convert" do 
  end

  test "convert without create " do 
  end

  test "convert without create json format " do 
  end

  test "destroy" do
  end

  test "enforce ownership on destroy" do
  end

  test "destroy won't let you delete last identifier in the publication" do
  end
end
