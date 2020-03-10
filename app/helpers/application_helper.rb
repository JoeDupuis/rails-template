module ApplicationHelper
  def flash_message(message, type: 'secondary')
    return nil if message.blank?

    tag.div(
      class: ['alert', "alert-#{type}"].join(' '),
      'data-controller': 'alert',
      'data-target': 'alert',
      role: 'alert'
    ) do
      message
    end
  end

  # Passes parameters to `link_to`, while ensuring the proper DOM is built
  # around the link for use in a navigation context.
  def menu_item(*args, i18n: nil, text: nil, policy: nil, policy_action: nil, **named_args)
    return nil unless policy.nil? || policy(policy).try((policy_action || :any?))
    url = url_for(*args)
    i18n ||= ['menu', url.gsub(%r{/+}, '.')].join('.')
    text ||= t(i18n)
    text = text[:index] if text.is_a? Hash
    classes = ['nav-link']
    # The current page only...
    classes << 'is-current' if url == url_for
    # Any "subpage"
    classes << 'is-active' if url_for.start_with?(url)

    tag.li(class: 'nav-item') do
      link_to text, *args, **named_args, class: classes.join(' ')
    end
  end

  def form_errors(instance, **locals)
    locals[:instance] = instance
    render partial: "application/form_errors", locals: locals
  end

  # Semantic shortcut to set the page's title.
  def title(title)
    content_for(:title) { title }
  end


  def link_back
    link_to t(:back), :back
  end
end
