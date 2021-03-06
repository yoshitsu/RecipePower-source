module ReferentsHelper

  def list_expressions referent, do_tag=true
    ("Expressions: "+(referent.expressions.collect { |expr| 
      "<br>&nbsp;&nbsp;'"+
      begin
        tag = Tag.find(expr.tag_id)
        locale = expr.locale || "(nil)"
        form = expr.form || "(nil)"
        (do_tag ? link_to(tag.name, tag) : tag.name)+
        "'(id #{tag.id.to_s}, form #{form}, locale #{locale})"
      rescue
        "<Missing tag##{expr.tag_id}>"
      end
    }.join(', ') || "none")).html_safe
  end
    
	def list_parents referent, do_tag=true
    ("Parents: "+(referent.parent_tags.collect { |tag| 
        (do_tag ? link_to(tag.name, tag) : tag.name)+
        "(id #{tag.id.to_s})"
      }.join(', ') || "none")).html_safe
  end
    
	def list_children referent, do_tag=true
    ("Children: "+
      (referent.child_tags.collect { |tag| 
        (do_tag ? link_to(tag.name, tag) : tag.name)+
        "(id #{tag.id.to_s})"
      }.join(', ') || "none")).html_safe
  end

	def summarize_ref_name referent, long=false
    extra = long ? "going by the name of " : ""
    "<i>#{referent.typename}</i> #{extra}<strong>'#{referent.name}'</strong> ".html_safe
	end
	
	def summarize_referent ref, label="...Meaning"
    ("<br>#{label}: ''#{link_to ref.name, referent_path(ref)}':"+
    summarize_ref_parents(ref)+
    summarize_ref_children(ref)).html_safe
  end
    
	def summarize_ref_parents ref, label = "...Categorized under"
    if ref.parents.size > 0
      ("<br>#{label}: "+
      (ref.parents.collect { |parent| link_to parent.name, parent.becomes(Referent) }.join ', ')).html_safe
    else
      ""
    end
	end
	
	def summarize_ref_children ref, label = "...Examples"
    if ref.children.size > 0
      ("<br>#{label}: "+
      (ref.children.collect { |child| link_to child.name, child.becomes(Referent) }.join ', ')).html_safe
    else
      ""
    end
	end
end
