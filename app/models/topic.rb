# A simple class to model a topic which can be used to create a collection
# encoding: utf-8
class Topic

  def initialize(topic)
    @topic = topic
  end

  def id
    return @topic
  end
end
