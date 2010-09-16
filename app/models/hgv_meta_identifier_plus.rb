class HGVMetaIdentifierPlus < HGVMetaIdentifier
  def self.find_by_publication_id publication_id
    return HGVMetaIdentifier.find_by_publication_id(publication_id).becomes(HGVMetaIdentifierPlus)
  end

  def self.find id
    return HGVMetaIdentifier.find(id).becomes(HGVMetaIdentifierPlus)
  end

  def valid_epidoc_attributes
    super.concat [:collection, :collection_place_name, :collection_temporary_notes, :collection_temporary_inventory_number,
    :hgv_date_offset, :hgv_date_precision,
    :from_century, :from_century_specifier_unit, :from_century_specifier_value_numeric, :from_century_specifier_value_string, :from_century_certainty,
    :from_year, :from_year_specifier_unit, :from_year_specifier_value_numeric, :from_year_specifier_value_string, :from_year_certainty,
    :from_month, :from_month_specifier_unit, :from_month_specifier_value_numeric, :from_month_specifier_value_string, :from_month_certainty,
    :from_day, :from_day_specifier_unit, :from_day_specifier_value_numeric, :from_day_specifier_value_string, :from_day_certainty,
    :to_century, :to_century_specifier_unit, :to_century_specifier_value_numeric, :to_century_specifier_value_string, :to_century_certainty,
    :to_year, :to_year_specifier_unit, :to_year_specifier_value_numeric, :to_year_specifier_value_string, :to_year_certainty,
    :to_month, :to_month_specifier_unit, :to_month_specifier_value_numeric, :to_month_specifier_value_string, :to_month_certainty,
    :to_day, :to_day_specifier_unit, :to_day_specifier_value_numeric, :to_day_specifier_value_string, :to_day_certainty,
    :on_century, :on_century_specifier_unit, :on_century_specifier_value_numeric, :on_century_specifier_value_string, :on_century_certainty,
    :on_year, :on_year_specifier_unit, :on_year_specifier_value_numeric, :on_year_specifier_value_string, :on_year_certainty,
    :on_month, :on_month_specifier_unit, :on_month_specifier_value_numeric, :on_month_specifier_value_string, :on_month_certainty,
    :on_day, :on_day_specifier_unit, :on_day_specifier_value_numeric, :on_day_specifier_value_string, :on_day_certainty,
    :publicationFascicle, :publicationSide, :publicationLine, :publicationPages, :publicationParts]
  end

  def self.attributes_xpath_hash

    basePathBody = "/TEI/text/body/div"
    basePathHeader = "/TEI/teiHeader/fileDesc/"
    publicationPath = "[@type='bibliography'][@subtype='principalEdition']/listBibl/"
    datePath = "sourceDesc/msDesc/history/origin/origDate[@type='hgvDate']/";

    date_types = ['from', 'to', 'on']
    term_types = ['century', 'year', 'month', 'day']
    xpaths = {
      '' => "num",
      '_specifier_unit' => "measure/@unit",
      '_specifier_value_numeric' => "measure/num[@type='ordinal']",
      '_specifier_value_string' => "measure/name",
      '_certainty' => "certainty[@locus='value']/@degree"
    }

    hgv_dates = {
      :hgv_date_offset =>
        basePathHeader + datePath + "offset",
      :hgv_date_precision =>
        basePathHeader + datePath + "precision/@degree"
    }
    date_types.each {|date_type|
      term_types.each {|term_type|
        xpaths.each_pair {|key, xpath|
          hgv_dates[(date_type + '_' + term_type + key).to_sym] = basePathHeader + datePath +
            "date[@type='" + date_type + "']/term[@type='" + term_type + "']/" + xpath
        }
      }
    }

=begin
hgv_date_offset = /TEI/teiHeader/fileDesc/sourceDesc/msDesc/history/origin/origDate[@type='hgvDate']/offset
hgv_date_precision = /TEI/teiHeader/fileDesc/sourceDesc/msDesc/history/origin/origDate[@type='hgvDate']/precision/@degree
from_century = /TEI/teiHeader/fileDesc/sourceDesc/msDesc/history/origin/origDate[@type='hgvDate']/date[@type='from']/term[@type='century']/num
from_century_specifier_unit = /TEI/teiHeader/fileDesc/sourceDesc/msDesc/history/origin/origDate[@type='hgvDate']/date[@type='from']/term[@type='century']/measure/@unit
from_century_specifier_value_numeric = /TEI/teiHeader/fileDesc/sourceDesc/msDesc/history/origin/origDate[@type='hgvDate']/date[@type='from']/term[@type='century']/measure/num[@type='ordinal']
from_century_specifier_value_string = /TEI/teiHeader/fileDesc/sourceDesc/msDesc/history/origin/origDate[@type='hgvDate']/date[@type='from']/term[@type='century']/measure/name
from_century_certainty = /TEI/teiHeader/fileDesc/sourceDesc/msDesc/history/origin/origDate[@type='hgvDate']/date[@type='from']/term[@type='century']/certainty[@locus='value']/@degree
=end
    HGVMetaIdentifier.attributes_xpath_hash.merge({
      :collection_place_name =>
        basePathHeader +
          "sourceDesc/msDesc/msIdentifier/placeName/settlement",
      :collection =>
        basePathHeader +
          "sourceDesc/msDesc/msIdentifier/collection",
      :collection_temporary_notes =>
        basePathHeader +
          "sourceDesc/msDesc/msIdentifier/altIdentifier[@type='temporary']/note",
      :collection_temporary_inventory_number =>
        basePathHeader +
          "sourceDesc/msDesc/msIdentifier/altIdentifier[@type='temporary']/idno[@type='invNo']",
      :publicationFascicle =>
        basePathBody + publicationPath +
          "bibl[@type='publication'][@subtype='principal']/biblScope[@type='fascicle']",
      :publicationSide =>
        basePathBody + publicationPath +
          "bibl[@type='publication'][@subtype='principal']/biblScope[@type='side']",
      :publicationLine =>
        basePathBody + publicationPath +
          "bibl[@type='publication'][@subtype='principal']/biblScope[@type='lines']",
      :publicationPages =>
        basePathBody + publicationPath +
          "bibl[@type='publication'][@subtype='principal']/biblScope[@type='pages']",
      :publicationParts =>
        basePathBody + publicationPath +
          "bibl[@type='publication'][@subtype='principal']/biblScope[@type='parts']",
    })
  end

  def sort doc
    sort_paths = {
      :msIdentifier => {
        :parent => '/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msIdentifier',
        :children => ['placename', 'collection', 'idno', 'altIdentifier']
      },
      :altIdentifier => {
        :parent => "/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msIdentifier/altIdentifier[@type='temporary']",
        :children => ['placename', 'collection', 'idno', 'note']
      }
    }

    sort_paths.each_value {|sort_path|
    
      if parent = doc.elements[sort_path[:parent]]
        sort_path[:children].each {|child_path|
          parent.elements.each(child_path){|child|
            parent.delete child
            parent.add child
          }
        }
      end
    }

   return doc 
  end

end
