class Repository
  attr_reader :master, :location
  
  def initialize(master)
    @master = master
    @location = master.name
  end
  
  def exists?
    master.has_repository?
  end
  
  def create
    master.update_attribute :has_repository, true
    # create a git repository
  end
  
  def destroy
    master.update_attribute :has_repository, false
    # destroy a git repository
  end
end