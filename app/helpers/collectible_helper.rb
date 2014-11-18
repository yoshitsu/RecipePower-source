module CollectibleHelper

  # Declare a button which either collects or edits an entity.
  def collect_or_edit_button entity, options={}
    options = options.merge class: "#{options[:class]} btn btn-default btn-xs", id: dom_id(entity)
    if entity.user_ids.include?(entity.collectible_user_id)
      template_link entity, "edit-collectible", "Edit", options.merge( :mode => :modal )
    else
      url = polymorphic_path(entity)+"/collect"
      label = "Collect"
      options[:class] << " collect-collectible-link"
      link_to_submit label, url, options
    end
  end

  def collect_or_edit_button_replacement entity, options={}
    [ "a.collect-collectible-link##{dom_id entity}", collect_or_edit_button(entity, options) ]
  end

  def collectible_masonry_item entity
    with_format("html") do render partial: "show_masonry_item" end
  end

  def collectible_masonry_item_replacement entity, destroyed=false
    [ ".masonry-item-contents."+dom_id(entity), (collectible_masonry_item(entity) unless destroyed) ]
  end

  def collectible_smallpic entity
    with_format("html") do render_to_string partial: "shared/recipe_smallpic" end
  end

  def collectible_smallpic_replacement entity, destroyed=false
    [ "."+recipe_list_element_class(@recipe), (collectible_smallpic(entity) unless destroyed) ]
  end

end
