class HGVMetaIdentifier < Identifier
  HGV_META_PATH_PREFIX = 'HGV_meta_EpiDoc'
  
  def to_path
    path_components = [ HGV_META_PATH_PREFIX ]
    # for now, assume the name is e.g. hgv2302zzr
    trimmed_name = name.sub(/^hgv/, '') # 2302zzr
    number = trimmed_name.sub(/\D/, '').to_i # 2302
    
    hgv_dir_number = ((number - 1) / 1000) + 1
    hgv_dir_name = "HGV#{hgv_dir_number}"
    hgv_xml_path = trimmed_name + '.xml'
    
    path_components << hgv_dir_name << hgv_xml_path
    
    # e.g. HGV_meta_EpiDoc/HGV3/2302zzr.xml
    return path_components.join('/')
  end
end