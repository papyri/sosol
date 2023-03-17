Rails.autoloaders.each do |autoloader|
  autoloader.inflector = Zeitwerk::Inflector.new
  autoloader.inflector.inflect(
    "jruby" => "JRuby",
    "cts" => "CTS",
    "ddb" => "DDB",
    "hgv" => "HGV",
    "dclp" => "DCLP"
  )
end
