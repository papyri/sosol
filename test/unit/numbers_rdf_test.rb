require 'test_helper'

class NumbersRDFTest < ActiveSupport::TestCase
  should "respond to a basic GET request at the root" do
    response = NumbersRDF::NumbersHelper::path_to_numbers_server_response('/')

    assert_equal '200', response.code
  end

  should "respond to an identifier request with the correct related identifiers" do
    response = NumbersRDF::NumbersHelper.identifier_to_identifiers('papyri.info/ddbdp/p.nyu;1;1')
    assert_equal ["papyri.info/ddbdp/p.nyu;1;1", "www.trismegistos.org/text/12481", "papyri.info/trismegistos/12481", "papyri.info/hgv/12481", "papyri.info/apis/nyu.apis.4782"], response
  end

  should "raise the appropriate timeout error" do
    # This test is unreliable, and should be replaced with e.g. Mocha on Net:HTTP to raise ::Timeout::Error
    # assert_raise NumbersRDF::Timeout do
    #   Timeout::timeout(0.1) do
    #     response = NumbersRDF::NumbersHelper::path_to_numbers_server_response('/')
    #   end
    # end
  end
end
