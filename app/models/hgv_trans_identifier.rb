class HGVTransIdentifier < Identifier
  HGV_TRANS_PATH_PREFIX = 'HGV_trans_EpiDoc'
  
  IDENTIFIER_NAMESPACE = 'hgv'
  TEMPORARY_COLLECTION = 'SoSOL'
  
  def to_path
    path_components = [ HGV_TRANS_PATH_PREFIX ]
    # assume the alternate name is e.g. hgv2302zzr
    trimmed_name = alternate_name.sub(/^hgv/, '') # 2302zzr

    hgv_xml_path = trimmed_name + '.xml'

    # HGV_trans_EpiDoc uses a flat hierarchy
    path_components << hgv_xml_path

    # e.g. HGV_trans_EpiDoc/2302zzr.xml
    return File.join(path_components)
  end
end