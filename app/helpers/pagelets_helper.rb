module PageletsHelper
  def pagelet_body_replacement entity_or_decorator=nil
    pbclass = "pagelet-body"
    div_options = { class: pbclass }
    if entity_or_decorator
      controller = (entity_or_decorator.is_a?(Draper::Decorator) ? entity_or_decorator.object : entity_or_decorator).class.to_s.underscore.pluralize
      div_options[:id] = pagelet_body_id entity_or_decorator
      content = with_format("html") { render_template(controller, :show) }
    else
      content = render_template(response_service.controller, response_service.action)
    end
    [ "div.#{pbclass}", content_tag(:div, content, div_options) ]
  end

  # Hang an id on the pagelet body for future conditional replacement
  def pagelet_body_id entity=nil
    entity ||= @decorator
    entity ? dom_id(entity) : "pagelet-body"
  end

  def pagelet_body_selector entity=nil
    "div.pagelet-body##{pagelet_body_id(entity)}"
  end
end
