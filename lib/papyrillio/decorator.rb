module Papyrillio

  class Decorator < Papyrillio::PapyrillioBase

    attr_accessor :title, :stylesheet

    def initialize title = 'Papyrillio Print Edition', stylesheet = 'public/stylesheets/papyrillio_decorator.css' #papyrillio_decorator.css
      super()
      @title = title
      @stylesheet = stylesheet
    end

    def adorn html
      header + html + footer
    end

    def header
      '
<html lang="en" xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta content="text/html;charset=UTF-8" http-equiv="content-type" />
    <meta content="noindex, nofollow" name="robots" />
    <title>' + @title + '</title>
    <link href="' + @stylesheet + '" media="screen" rel="stylesheet" type="text/css" />
  </head>
  <body>
    <span>' + @start.to_s + '</span>        
      '
    end

    def footer
      '
  </body>
</html>
      '      
    end

  end

end