class Repository
  attr_reader :master, :location
  
  def initialize(master)
    @master = master
    @location = master.name
  end
  
  
end