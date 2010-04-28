module Papyrillio
  class Publishee
    attr_accessor :label, :hgv_folder, :hgv_file, :ddb_file, :file_index, :print_index, :html 

    def initialize
      @label = ''
      @hgv_folder = nil
      @hgv_file = nil
      @ddb_file = nil
      @file_index = 0
      @print_index = 0
      @html = ''
    end
  end
end