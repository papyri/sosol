module BagitHelper
  require 'bagit'
  require 'zip/zip'
  require 'zip/zipfilesystem'


  # Creates a BagIt Archive from a Publication's contents
  # if the publication contains annotations targeting CTS identifiers, 
  # we will create this as a Research Object Bundle
  # adhering to https://w3id.org/ro/bagit/profile
  # otherwise it will just be a simple bagit archive
  # - *Args*  :
  #   - +publication+ -> the Publication to bag
  # - *Yields* :
  #   - temp zipfile to send and the filename
  def self.bagit(publication,current_user) 
    now_iso = Time.now.iso8601
    # setup the research object bundle manifest in case we need it
    ro_manifest = { }
    ro_manifest['@context'] = ["https://w3id.org/bundle/context"]
    ro_manifest['@id'] = '../'
    ro_manifest['createdBy'] = { 'name' => current_user.full_name, 'uri' => current_user.uri }
    ro_manifest['createdOn'] = now_iso
    ro_manifest['aggregates'] = []
    ro_manifest['annotations'] = []

    # TODO eventually it would be nice to generate a handle for the archive
    file_friendly_name = publication.title.gsub(/[\\\/:."*?<>|\s]+/, "-")
    bagit_name = "perseidspublication_" + publication.id.to_s + "_" + now_iso
    Dir.mktmpdir { |dir|
      bagdir = File.join(dir.to_s, bagit_name)
      Dir.mkdir bagdir
      bag = BagIt::Bag.new bagdir
      local_aggregates = []
      publication.identifiers.each do |id|
        if (id.respond_to?(:as_ro))
          ro = id.as_ro
        end
        unless ro.nil?
          if (ro['annotations'].size > 0)
            # add the content to the annotations directory
            bag.add_tag_file(File.join('metadata','annotations',id.download_file_name)) do |io|
              io.puts id.xml_content
            end
            #update the ro annotations manifest
            ro_manifest['annotations'].concat(ro['annotations'])
          else
            bag.add_file( id.download_file_name ) do |io|
              io.puts id.xml_content
            end
            #update the ro aggregates manifest
            ro_manifest['aggregates'].concat(ro['aggregates'])
          end
        end
      end
      if ro_manifest['annotations'].size == 0
        ro_manifest.delete('annotations')
      end
      bag.add_tag_file(File.join('metadata','manifest.json')) do |io|
       io.puts JSON.pretty_generate(ro_manifest)
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

  def self.generate_prov_derivation(source,derived_from)
    prov = {
      '@context'=> {
        'prov'=> "http://www.w3.org/ns/prov#"
       },
      '@id' =>  source,
      '@type' => 'prov:Entity',
      'prov:wasDerviedFrom' => {
        '@type' => 'prov:Entity',
        '@id'   => dervied_from
      }
    }
    JSON.pretty_generate(prov)
  end

end
