module Papyrillio

  class Transformer < Papyrillio::PapyrillioBase
    attr_accessor :transformation_file, :parameters

    def initialize transformation_file = nil, parameters = {}
      super()
      @transformation_file = transformation_file
      @parameters = parameters
    end

    def convert publishees
      index = 1
      publishees.each{|publishee|

        head = body = apparatus = tail = ''

        head = transform publishee.hgv_file, @transformation_file, @parameters.merge({'meta-style' => 'sammelbuch_header', 'scaffolding'  => 'off'})
        body = transform publishee.ddb_file, @transformation_file, @parameters.merge({'meta-style' => 'sammelbuch', 'scaffolding'  => 'off'})
        apparatus = ''
        tail = transform publishee.hgv_file, @transformation_file, @parameters.merge({'meta-style' => 'sammelbuch_footer', 'scaffolding'  => 'off'})

        log_progress (index.to_f / publishees.length * 100).round

        index += 1
        publishee.html = '<div class="article" style="border-bottom: solid 1px #c0c0c0;">' + head + body + tail + apparatus + '</div>'

      }

      puts ''
      
      publishees

    end

    protected

    def transform transformee, transformator, transformables

      if transformee && transformator
          JRubyXML.apply_xsl_transform(
            JRubyXML.stream_from_string(transformee.data),
            JRubyXML.stream_from_file(transformator),
            transformables).gsub(/\<\?xml.+\?\>/, '')
      else
        ''
      end

    end

  end

end