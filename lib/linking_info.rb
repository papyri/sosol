module LinkingInfo
  class LinkingInfo
    attr_accessor :controller, :action, :id

    def initialize(controller, action, id)
      @controller = controller
      @action = action
      @id = id
    end
  end
end
