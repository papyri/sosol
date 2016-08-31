module Api::V1

  class CommunitiesController < ApiController
    rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
    include Swagger::Blocks

    skip_before_filter :authorize
    before_filter only: [:list] do
      doorkeeper_authorize! :write, :read
    end

    swagger_path "/communities" do
      operation :get do
        key :description, "Lists available communities"
        key :operationId, 'getCommunities'
        key :tags, [ 'community' ]
        response 200 do
          key :description, 'communities get response'
          schema do
            key :'$ref' , :Community
          end
        end
        security do
          key :sosol_auth, ['write','read']
        end
        response :default do
          key :description, 'unexpected error'
          schema do
            key :'$ref', :ApiError
          end
        end
      end
    end

    def index
      @communities = []
      @current_user.community_memberships.each do |community|
        if community.is_submittable? #check to see that we can submit to community
          @communities << build(community)
        end
      end
      (Community.all - @current_user.community_memberships).each  do |community|
        if community.is_submittable? && community.allows_self_signup?
          @communities << build(community)
        end
      end
      render :json => @communities
    end

    private

    def build(community)
      {
        :id => community.id,
        :name => community.name,
        :friendly_name => community.friendly_name,
        :description => community.description
      }
    end
  end

end
