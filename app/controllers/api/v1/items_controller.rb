module Api::V1
  class ItemsController < ApiController
 
    skip_before_filter :authorize 
    before_filter :doorkeeper_authorize!

    def user_info
      ping
    end

    def create
      api_item_create
    end

  end
end
