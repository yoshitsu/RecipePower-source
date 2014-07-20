module StreamHelper
  # Leave a link for stream firing
  def stream_link path, options={}
    options[:onclick] = 'RP.stream.go(event);'
    options[:data] = {} unless options[:data]
    options[:data][:path] = path
    link_to "Click to load", "#", options
  end

  # Render an element of a collection, depending on its class
  def render_stream_item element
    case element
      when Recipe
        @recipe = element
        @recipe.current_user = @user.id
        content_tag( :div,
                     render("shared/recipe_grid"),
                     class: "masonry-item" )
      when FeedEntry
        @feed_entry = element
        render "shared/feed_entry"
      when Fixnum
        "<p>#{element}</p>"
      else
        # Default is to set instance variable @<Klass> and render "<klass>s/<klass>"
        ename = element.class.to_s.downcase
        self.instance_variable_set("@"+ename, element)
        render partial: "#{ename.pluralize}/show_table_row", locals: { ename.to_sym => element }
    end
  end

  def package_stream_item selector, elmt
    { elmt: elmt, selector: selector }
  end

  # Package up a collection element for passing into a stream
  def emit_stream_item element
    elmt = render_stream_item element
    return { elmt: elmt }
    selector =
        case element
          when Recipe
            '#masonry-container'
          when FeedEntry
            'ul.feed_entries'
          when Tag
            'tbody.collection_list'
          else
            '.collection_list'
        end
    package_stream_item selector, elmt
  end

end