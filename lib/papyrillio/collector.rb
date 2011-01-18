module Papyrillio

  #
  # Collector
  #
  # simply loads all files from all user repositories
  #

  class Collector < Papyrillio::PapyrillioBase

    def get
      @publishees ? @publishees : retrieve;
    end

    protected

    def retrieve
      log '--> Collector'

      @publishees = []
      User.find(:all).each {|user|
        log '| user ' + user.name
        Publication.find_all_by_owner_id(user.id).each{|publication|
          log '|__ publication ' + publication.title
          @publishees[@publishees.length]  = Publishee.new :publication => publication, :user => user.name, :label => publication.title
        }
      }

      @publishees
    end
  end

  #
  # CollectorXpathPattern
  #
  # looks for a special pattern within a given EpiDoc attribute
  #

  class CollectorXpathPattern < Papyrillio::Collector
    attr_accessor :attribute, :pattern

    def initialize attribute, pattern
      super()
      @attribute = attribute
      @pattern = pattern
    end

    def to_s
      self.class.to_s + ': pattern[' + @pattern.to_s + '] attribute[' + @attribute.to_s + ']'
    end

    protected

    def retrieve
      @publishees = super()

      log '--> CollectorXpathPattern'

      if @publishees.length > 0
        index = 1.0
        total = @publishees.length

        @publishees.delete_if{|publishee|
          log_progress (index / total  * 100).round()
          index += 1
          if publishee.hgv_meta_identifier
            publishee.hgv_meta_identifier[@attribute].to_s[@pattern] ? false : true
          else
            true
          end
        }

        log_progress 100
        puts ''
        @publishees.each{|p| log 'publication  ' + p.label }
      else
        log 'nothing to do'
      end

    end
  end

  #
  # FakeCollector
  #
  # loads hard coded publication ids
  #

  class FakeCollector < Papyrillio::Collector

    protected

    def retrieve
      log '--> FakeCollector'

      [Publishee.new(:publication => Publication.find_by_id(76))]
    end
  end

end