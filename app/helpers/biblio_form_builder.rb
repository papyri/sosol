class BiblioFormBuilder < ActionView::Helpers::FormBuilder
  def text_field label, *args
    @template.content_tag('label', label.to_s.humanize, :for => @object_name + '_' + label.to_s) + super
  end
end