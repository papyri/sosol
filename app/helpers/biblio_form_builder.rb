# Helper for creation of forms for class +BiblioIdentifier+
class BiblioFormBuilder < ActionView::Helpers::FormBuilder
  # Generates a text field with a preceding label tag
  # - *Args*  :
  #   - +label+ → biblio key, e.g. +:articleTitle+
  # - *Returns* :
  #   - HTML label and input field of type text
  def text_field(label, *args)
    make_label(label) + super
  end

  # Generates a label tag
  # - *Args*  :
  #   - +label+ → biblio key, e.g. +:articleTitle+
  # - *Returns* :
  #   - HTML label
  def label(label, *_args)
    make_label label
  end

  # Generates a select box with a preceding label tag
  # - *Args*  :
  #   - +label+ → biblio key, e.g. +:articleTitle+
  #   - options → HTML options, defaults to empty +Array+
  # - *Returns* :
  #   - HTML label and select box
  def select(label, options = [], *args)
    options = make_options(label)
    make_label(label) + super
  end

  # Generates a text area field with a preceding label tag
  # - *Args*  :
  #   - +label+ → biblio key, e.g. +:articleTitle+
  # - *Returns* :
  #   - HTML label and text area field
  def text_area(label, *args)
    make_label(label) + super
  end

  # Provides translated values to be used in a drop down box
  # - *Args*  :
  #   - +label+ → key, +:language+, +:language+, +:subtype+, +:publisherType+ or +:shortTitleResponsibility+
  # - *Returns* :
  #   - +Array+ of +Array+s that can be used with rails' options_for_select function for special biblio keys
  def make_options(label)
    {
      language: [
        ['', ''],
        [I18n.t('language.fr'), 'fr'],
        [I18n.t('language.en'), 'en'],
        [I18n.t('language.de'), 'de'],
        [I18n.t('language.it'), 'it'],
        [I18n.t('language.es'), 'es'],
        [I18n.t('language.la'), 'la'],
        [I18n.t('language.el'), 'el']
      ],
      supertype: [
        ['', ''],
        [I18n.t('biblio.type.book'), 'book'],
        [I18n.t('biblio.type.journal'), 'journal'],
        [I18n.t('biblio.type.article'), 'article'],
        [I18n.t('biblio.type.review'), 'review']
      ],
      subtype: [
        ['', ''],
        [I18n.t('biblio.subtype.book'), 'book'],
        [I18n.t('biblio.subtype.journal'), 'journal'],
        [I18n.t('biblio.subtype.other'), 'other'],
        [I18n.t('biblio.subtype.edited'), 'edited'],
        [I18n.t('biblio.subtype.authored'), 'authored']
      ],
      publisherType: [
        [I18n.t('biblio.publisherType.name'), 'publisher'],
        [I18n.t('biblio.publisherType.place'), 'pubPlace']
      ],
      shortTitleResponsibility: [
        [I18n.t('biblio.shortTitleResponsibility.bp'), 'BP'],
        [I18n.t('biblio.shortTitleResponsibility.cl'), 'Checklist']
      ],
      category: [
        ['', ''],
        [I18n.t('biblio.category.papyrus'), 'Papyri'],
        [I18n.t('biblio.category.ostracon'), 'Ostraca'],
        [I18n.t('biblio.category.corpora'), 'Corpora'],
        [I18n.t('biblio.category.series'), 'Series']
      ]
    }[label]
  end

  # Provides translated label tag for biblio data
  # - *Args*  :
  #   - +label+ → key, any valid biblio :key
  # - *Returns* :
  #   - HTLM label tag
  def make_label(label)
    @template.content_tag('label', I18n.t("biblio.label.#{label}"), title: BiblioIdentifier.XPATH(label.to_s),
                                                                    for: "#{@object_name}_#{label}", id: "label_#{@object_name}_#{label}")
  end
end
