module TemplateHelper

  # Provide a link that can be short-circuited by resorting to a template of the class given by classname
  # Relevant options:
  # trigger: true if the link should be fired immediately
  def template_link entity, template_id, label, styling, options={}
    if entity.is_a? Templateer
      # Assert a :template datum without disturbing any existing :data options
      options[:template] = { id: template_id, subs: entity.data(options.delete(:attribs)) }
    end
    link_to_submit label, polymorphic_path([:tag, entity], styling: styling), button_styling(styling, options)
  end

end