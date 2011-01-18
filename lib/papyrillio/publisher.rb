module Papyrillio
  class Publisher < Papyrillio::PapyrillioBase
    attr_accessor :collector, :organiser, :transformer, :aggregator, :decorator, :printer

    def initialize params = []
      super()
      @collector   = params[:collector]   ? params[:collector]   : Papyrillio::Collector.new
      @organiser   = params[:organiser]   ? params[:organiser]   : Papyrillio::Organiser.new
      @transformer = params[:transformer] ? params[:transformer] : Papyrillio::Transformer.new
      @aggregator  = params[:aggregator]  ? params[:aggregator]  : Papyrillio::Aggregator.new
      @decorator   = params[:decorator]   ? params[:decorator]   : Papyrillio::Decorator.new
      @printer     = params[:printer]     ? params[:printer]     : Papyrillio::Printer.new
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