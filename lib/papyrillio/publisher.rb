module Papyrillio
  class Publisher < Papyrillio::PapyrillioBase
    attr_accessor :collector, :organiser, :transformer, :aggregator, :decorator, :printer

    def initialize collector = nil, organiser = nil, transformer = nil, aggregator = nil, decorator = nil, printer = nil
      super()
      @collector   = collector   ? collector   : Papyrillio::Collector.new
      @organiser   = organiser   ? organiser   : Papyrillio::Organiser.new
      @transformer = transformer ? transformer : Papyrillio::Transformer.new
      @aggregator  = aggregator  ? aggregator  : Papyrillio::Aggregator.new
      @decorator   = decorator   ? decorator   : Papyrillio::Decorator.new
      @printer     = printer     ? printer     : Papyrillio::Printer.new
    end

    def release

      log '----> Start collection process'
      log @collector

      publishees = @collector.get

      log publishees.length.to_s + ' item' + (publishees.length == 1 ? '' : 's') + ' found'

      log '----> Start organising'

      publishees = @organiser.sort publishees

      log '----> Start transformation'

      publishees = @transformer.convert publishees

      log '----> Start aggregating'

      html  = @aggregator.combine publishees

      log '----> Start decoration'

      html = @decorator.adorn html

      log '----> Start saving generated contents'

      html  = @printer.save html

      log '----> Finish release'
    end

    def to_s
      @collector.to_s + "\n" +
        @organiser.to_s + "\n" +
        @transformer.to_s + "\n" +
        @aggregator.to_s + "\n" +
        @decorator.to_s + "\n" +
        @printer.to_s + "\n"
    end

  end
end