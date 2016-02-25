include DclpMetaIdentifierHelper

class DclpMetaIdentifiersController < HgvMetaIdentifiersController

  def edit
    find_identifier
    @identifier.get_epidoc_attributes
    @is_editor_view = true
  end

  # Provides a small data preview snippets (values for when, notBefore and notAfter as well as the hgv formatted value) for display within the hgv metadata editor
  # Assumes that hgv metadata is passed in via post and uses the values containd in hash entry »:textDate« to generate preview snippets for hgv date.
  # Side effect on +@update+
  def biblio_preview
    @update = '';
    if !params[:biblio].nil?
      @update = '#' + params[:biblio] + ' ' + [
        'Alexander Jones, Astronomical Papyri from Oxyrhynchus (P. Oxy. 4133-4300a). Volumes I and II., (Philadelphia 1999).',
        'Orsolina MONTEVECCHI, Bibbia e papiri. Luce dai papiri sulla Bibbia greca., (Barcelona 1999).',
        'Fabrizio CONCA ed., Ricordando Raffaele Cantarella. Miscellanea di studi, (Milano 1999).',
        'David G. MARTINEZ, P. Michigan XIX. Baptized for Our Sakes: A Leather Trisagion from Egypt (P. Mich. 799)., (Stuttgart Leipzig 1999).'
      ][rand(0..3)]
    end
  end

  protected
  
    # Sets the identifier instance variable values
    # - *Params*  :
    #   - +id+ -> id from identifier table of the DCLP Text
    def find_identifier
      @identifier = DCLPMetaIdentifier.find(params[:id].to_s)
    end
end
