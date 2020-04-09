ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  class_attr_index = html_tag.index 'class="'
  class_attr_index  = nil if class_attr_index.try :>, html_tag.index('>') #support label wrapping field
  if class_attr_index
    html_tag.insert class_attr_index + 7, 'field_with_errors '.html_safe
  else
    html_tag.insert html_tag.index('>'), ' class="field_with_errors"'.html_safe
  end
end
