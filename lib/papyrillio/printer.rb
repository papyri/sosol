module Papyrillio

  #
  # Printer
  #
  # simply writes content to disk
  #

  class Printer < Papyrillio::PapyrillioBase

    def initialize filepath = nil
      super()
      @filepath = filepath || @start.strftime('PapyrillioPrinter-%Y-%m-%d.html') 
    end

    def save html
      f = File.new @filepath, 'w'
      f.write html
      f.close
    end

  end

  #
  # OpenOfficePrinter
  #
  # builds OpenOffice document and writes this file to disk
  #

  class OpenOfficePrinter < Printer

    def save xml
      log '--> OpenOfficePrinter'
      template_file = File.join(RAILS_ROOT, 'data', 'OOo', 'Sammelbuch.odt')
      working_directory = File.join(RAILS_ROOT, 'tmp', 'print', 'Sammelbuch')
      working_file = File.join(working_directory, 'Sammelbuch' + '' + '.odt')
      content_file = File.join(working_directory, 'content.xml')

      # delete previous working directory
      execute 'rm -rf ' + working_directory

      # setup new working directory
      execute 'mkdir ' + working_directory
      execute 'cp ' + template_file + ' ' + working_directory + '/'
  
      # write content.xml
      File.open(content_file, 'w') {|f| f.write(xml) }
  
      # zip content file into office document
      execute 'zip -j ' + working_file + ' ' + content_file
    end
    
    protected

      def execute command
        log 'execute command »' + command + '«'
        `#{command}`
      end
  end

end