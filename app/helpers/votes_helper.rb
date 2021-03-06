module VotesHelper

  # Link to submit a vote on the given entity. 'up' is true for an upvote
  def vote_link entity, up, options={}
    polymorphic_path([:vote, entity], options.merge(entity_type: entity.class.to_s, up: up)) rescue nil
  end

  def vote_params entity, up
    { entity_type: entity.class.to_s.downcase, entity_id: entity.id, up: up }
  end

  def vote_count_class style
    "vote-count-"+style
  end

  def vote_button_class state_to, state_now, style
    "vote-button glyphicon glyphicon-thumbs-#{state_to} #{'active' if state_now && state_now==state_to}"
  end

  def vote_div_class style
    "vote-div-"+style
  end

end
