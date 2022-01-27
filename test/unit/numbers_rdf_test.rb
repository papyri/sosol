# frozen_string_literal: true

require 'test_helper'

class NumbersRDFTest < ActiveSupport::TestCase
  should 'respond to a basic GET request at the root' do
    response = NumbersRDF::NumbersHelper.path_to_numbers_server_response('/')

    assert_equal '200', response.code
  end

  should 'raise the appropriate timeout error' do
    # This test is unreliable, and should be replaced with e.g. Mocha on Net:HTTP to raise ::Timeout::Error
    # assert_raise NumbersRDF::Timeout do
    #   Timeout::timeout(0.1) do
    #     response = NumbersRDF::NumbersHelper::path_to_numbers_server_response('/')
    #   end
    # end
  end
end
