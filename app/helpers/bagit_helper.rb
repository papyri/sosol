module BagitHelper
  require 'bagit'
  require 'zip/zip'
  require 'zip/zipfilesystem'

  # Creates a BagIt Archive from a Publication's contents
  # - *Args*  :
  #   - +publication+ -> the Publication to bag
  # - *Yields* :
  #   - temp zipfile to send and the filename
  def self.bagit(publication) 
    file_friendly_name = publication.title.gsub(/[\\\/:."*?<>|\s]+/, "-")
    bagit_name = "perseidspublication_" + publication.id.to_s + "_" + Time.now.strftime("%a%d%b%Y_%H%M")
    Dir.mktmpdir { |dir|
      bagdir = File.join(dir.to_s, bagit_name)
      Dir.mkdir bagdir
      bag = BagIt::Bag.new bagdir
      publication.identifiers.each do |id|
        bag.add_file( id.download_file_name ) do |io|
        end
      end
      bag.manifest!
      zipfile = bagit_name + ".zip"
      entries = Dir.entries(dir) - %w(. ..)
      Dir.mktmpdir { |zipdir|
        tfile = File.join(zipdir,zipfile)
        ::Zip::File.open(tfile, ::Zip::File::CREATE) do |io|
          write_entries dir, entries, '', io
        end
        yield [tfile,zipfile]
      }
    }
  end

  # Recurses in a directory and writes its contents to a zip
  # Copied from https://github.com/rubyzip/rubyzip/blob/05916bf89181e1955118fd3ea059f18acac28cc8/samples/example_recursive.rb
  def self.write_entries(input_dir, entries, path, io)
    entries.each do |e|
      zip_file_path = path == '' ? e : File.join(path, e)
      disk_file_path = File.join(input_dir, zip_file_path)

      if File.directory? disk_file_path
        recursively_deflate_directory(input_dir, disk_file_path, io, zip_file_path)
      else
        put_into_archive(disk_file_path, io, zip_file_path)
      end
    end
  end

  # Recursively deflates a directory for adding to a zip
  # Copied from https://github.com/rubyzip/rubyzip/blob/05916bf89181e1955118fd3ea059f18acac28cc8/samples/example_recursive.rb
  def self.recursively_deflate_directory(input_dir, disk_file_path, io, zip_file_path)
    io.mkdir zip_file_path
    subdir = Dir.entries(disk_file_path) - %w(. ..)
    write_entries input_dir, subdir, zip_file_path, io
  end

  # add a disk file to a zip archive
  def self.put_into_archive(disk_file_path, io, zip_file_path)
    io.add(zip_file_path, disk_file_path)
  end

end
