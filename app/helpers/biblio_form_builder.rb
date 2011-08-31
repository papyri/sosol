class BiblioFormBuilder < ActionView::Helpers::FormBuilder
  def text_field label, *args
    make_label(label) + super
  end
  
  def label label, *args
    make_label label
  end
  
  def select label, options = [], *args
    options = make_options(label)
    make_label(label) + super
  end

  def text_area label, *args
    make_label(label) + super
  end
  
  def make_options label
    {
      :language => [
        ['', ''],
        [I18n.t('language.fr'), 'fr'],
        [I18n.t('language.en'), 'en'],
        [I18n.t('language.de'), 'de'],
        [I18n.t('language.it'), 'it'],
        [I18n.t('language.es'), 'es'],
        [I18n.t('language.la'), 'la'],
        [I18n.t('language.el'), 'el']
      ],
      :type => [
        ['', ''],
        [I18n.t('biblio.type.book'), 'book'],
        [I18n.t('biblio.type.journal'), 'journal'],
        [I18n.t('biblio.type.article'), 'article'],
        [I18n.t('biblio.type.review'), 'review']
      ],
      :subtype => [
        ['', ''],
        [I18n.t('biblio.subtype.book'), 'book'],
        [I18n.t('biblio.subtype.journal'), 'journal'],
        [I18n.t('biblio.subtype.other'), 'other'],
        [I18n.t('biblio.subtype.edited'), 'edited'],
        [I18n.t('biblio.subtype.authored'), 'authored']
      ]
    }[label]
  end
  
  def make_label label
    @template.content_tag('label', I18n.t('biblio.label.' + label.to_s), :title => BiblioIdentifier.XPATH(label.to_s), :for => @object_name + '_' + label.to_s, :id => 'label_' + @object_name + '_' + label.to_s)
  end
end