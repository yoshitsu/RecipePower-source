require 'token_input.rb'
require 'string_utils.rb'
require 'uri_utils.rb'

class InvitationsController < Devise::InvitationsController
  # skip_before_filter :verify_authenticity_token
  prepend_before_filter :login_required # No invitations unless logged in!

  def after_invite_path_for(resource)
    collection_path
  end

  # GET /resource/invitation/new
  def new
    self.resource = resource_class.new(invitation_message: "Here's a recipe that I'm really into right now. Take a look and tell me what you think.")
    resource.shared_recipe = params[:recipe_id]
    @recipe = resource.shared_recipe && Recipe.find(resource.shared_recipe)
    self.resource.invitation_issuer = current_user.polite_name
    # dialog_boilerplate(@recipe ? :share : :new)
    if @recipe
      smartrender :action => :share
    else
      smartrender
    end
  end

  # GET /resource/invitation/accept?invitation_token=abcdef
  def edit
    x=2
    logger.debug "Entering InvitationsController#edit"
    if params[:invitation_token] &&
        (self.resource = resource_class.find_by_invitation_token(params[:invitation_token], false))
      resource.extend_fields # Default values for name, etc.
      # RpEvent.post resource, :invitation_responded, nil, resource_class.find(resource.invited_by_id)
      if response_service.dialog? # Referred by on-site link => do dialog
        smartrender
      else
        # Invitation link was followed => issue the 'responded' event
        redirect_to home_path(:invitation_token => params[:invitation_token])
      end
    else
      set_flash_message(:alert, :invitation_token_invalid)
      redirect_to after_sign_out_path_for(resource_name)
    end
  end

  # POST /resource/invitation
  def create
    unless current_user
      logger.debug "NULL CURRENT_USER in invitation/create without raising authenticity error"
      raise ActionController::InvalidAuthenticityToken
    end

    alerts = [] # This will be an array of messages to report back to the user
    popups = []

    # If dialog has no invitee_tokens, get them from email field
    params[resource_name][:invitee_tokens] = params[resource_name][:invitee_tokens] ||
        params[resource_name][:email].split(',').collect { |email| %Q{'#{email.downcase.strip}'} }.join(',')
    # Check email addresses in the tokenlist for validity
    @staged = User.new params[resource_name] # invite_resource
    for_sharing = @staged.shared_recipe && true

    # It is an error to provide a bogus email address
    err_address =
        @staged.invitee_tokens.detect { |token|
          token.kind_of?(String) && !(token =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i)
        }
    if err_address || @staged.invitee_tokens.empty? # if there's an invalid email, go back to the user
      @staged.errors.add (for_sharing ? :invitee_tokens : :email),
                         err_address.blank? ?
                             "Can't send an invitation without an email to send it to!" :
                             "'#{err_address}' doesn't look like an email address."
      self.resource = @staged
      # dialog_boilerplate(for_sharing ? :share : :new)
      smartrender :action => (for_sharing ? :share : :new)
      return
    end

    # Now that the invitee tokens are "valid", send mail to each
    breakdown = UserServices.new(@staged).analyze_invitees(current_user)
    self.resource = resource_class.new()
    # Do invitations and/or shares, as appropriate
    breakdown[:invited] = []
    breakdown[:failures] = []
    # breakdown[:to_invite] is the list of complete outsiders who need invitations as well as shares
    # breakdown[:pending] are invitees who haven't yet accepted
    (breakdown[:to_invite]+breakdown[:pending]).each do |invitee|
      # Fresh invitations to a genuine external user
      begin
        pr = params[resource_name]
        pr[:email] = (invitee.kind_of?(User) ? invitee.email : invitee).downcase
        pr[:skip_invitation] = true # Hold off on invitation so we can re-direct to share, as nec.
        @resource = self.resource = resource_class.invite!(pr, current_inviter)
        @resource.invitation_sent_at = Time.now.utc
        if for_sharing
          @notification = @resource.post_notification(:share_recipe, current_inviter, what: params[resource_name][:shared_recipe])
          @resource.save(validate: false) # ...because the invitee doesn't have a handle yet
          @resource.issue_instructions(:sharing_invitation_instructions,
                                       notification_token: @notification.notification_token,
                                       subject: @resource.invitation_issuer+" has something tasty for you")
        else
          @resource.save(validate: false) # ...because the invitee doesn't have a handle yet
          @resource.issue_instructions(:invitation_instructions)
        end
        breakdown[:invited] << @resource
        #        rescue Exception => e
        #          breakdown[:failures].push({ email: invitee.email, error: e.to_s })
        #          self.resource = nil
      end
    end
    what_to_send = for_sharing ? "a sharing notice" : "an invitation"
    popups <<
        breakdown.report(:invited, :email) { |names, count|
          subj_verb = (count > 1) ?
              (what_to_send.sub(/^[^\s]*\s*/, '').capitalize+"s are winging their way") :
              (what_to_send.capitalize+" is winging its way")
          %Q{Yay! #{subj_verb} to #{names}}
        }
    alerts <<
        breakdown.report(:failures) { |items, count|
          what_to_send = what_to_send.sub(/^[^\s]*\s*/, '')+"s" if count > 1
          "Couldn't send #{what_to_send} to:"+
              "<ul>" + items.collect { |item| "<li>#{item[:email]}: #{item[:error]}</li>" }.join + "</ul>"
        }

    if for_sharing
      # All categories of user get notified of the share
      (breakdown[:new_friends]+breakdown[:redundancies]).each do |sharee|
        # Mail generic share notice with action button to collect recipe
        # Cook Me Later: add to collection
        sharee.invitation_message = params[:user][:invitation_message]
        sharee.save
        sharee.notify(:share_recipe, current_user, what: params[resource_name][:shared_recipe])
        breakdown[:invited] << sharee
      end
      popups << breakdown.report(:redundancies, :salutation) { |names, count| %Q{#{names} #{count > 1 ? "have" : "has" } been notified on your behalf.} }
    else
      alerts << [
          breakdown.report(:redundancies, :handle) { |names, count|
            "You're already friends with #{names}." },
          breakdown.report(:pending, :email) { |names, count|
            verb = count > 1 ? "have" : "has"
            %Q{#{names} #{verb} already been invited but #{verb}n't accepted.}
          },
          breakdown.report(:new_friends, :handle) { |names, count|
            %Q{#{names} #{count > 1 ? "are" : "is"} already on RecipePower, so we've added them to your friends.}
          }
      ]
    end
    @recipe = for_sharing && Recipe.find(@staged.shared_recipe)
    respond_to { |format|
      format.json {
        response = {done: true}
        if breakdown[:new_friends].count > 0
          response[:entity] = breakdown[:new_friends].collect { |nf|
            unless current_user.followee_ids.include? nf.id
              current_user.followees << nf
              current_user.save
            end
          }
        end
        alerts = alerts.flatten.compact
        popups = popups.flatten.compact
        if alerts.empty?
          # If there's a single popup, report it in a popup, otherwise use an alert
          response[popups.count == 1 ? :popup : :alert] = popups.join('<br>').html_safe unless popups.empty?
        else
          # Alerts get reported as alerts
          response[:alert] = (popups+alerts).compact.join('<br>').html_safe
        end
        render json: response
      }
    }
    return
    # Now we're done processing invitations, notifications and shares. Report back.
    ##################
    email = params[resource_name][:email].downcase
    if resource = User.where(email: email).first
      resource.errors[:email] << "We already have a user with that email address"
    else
      params[resource_name][:invitation_message] =
          splitstr(params[resource_name][:invitation_message], 100)
      begin
        pr = params[resource_name]
        pr[:skip_invitation] = true
        @resource = self.resource = resource_class.invite!(pr, current_inviter)
        @resource.invitation_sent_at = Time.now.utc
        @resource.shared_recipe = Recipe.first.id
        @resource.save(validate: false) # ...because the invitee doesn't have a handle yet
        @resource.issue_instructions(:share_instructions)
      rescue Exception => e
        self.resource = nil
      end
    end
    if resource && resource.errors.empty? # Success!
      set_flash_message :notice, :send_instructions_html, :email => self.resource.email
      notice = "Yay! An invitation is winging its way to #{resource.email}"
      respond_with resource, :location => after_invite_path_for(resource) do |format|
        format.json { render json: {done: true, alert: notice} }
      end
    elsif !resource
      if e.class == ActiveRecord::RecordNotUnique
        other = User.find_by_email email
        flash[:notice] = "What do you know? '#{other.handle}' has already been invited/signed up."
      else
        error = "Sorry, can't create invitation for some reason."
        if e
          e.to_s.split("\n").each { |line|
            error << "\n"+line if (line =~ /DETAIL:/)
          }
        end
        flash[:error] = error
      end
      redirect_to collection_path
    elsif resource.errors[:email]
      if (other = User.where(email: resource.email).first)
        # HA! request failed because email exists. Forget the invitation, just make us friends.
        id = other.email
        id = other.handle if id.blank?
        id << " (aka #{other.handle})" if (other.handle != id)
        if current_inviter.followee_ids.include? other.id
          notice = "#{id} is already on RecipePower--and a friend of yours."
        else
          current_inviter.followees << other
          current_inviter.save
          notice = "But #{id} is already on RecipePower! Oh happy day!! <br>(We've gone ahead and made them your friend.)".html_safe
        end
        smartrender :action => :new
      else # There's a resource error on email, but not because the user exists: go back for correction
        render :new
      end
    else
      respond_with_navigational(resource) { render :new }
    end
  end

  # PUT /resource/invitation
  def update
    self.resource = resource_class.accept_invitation!(params[resource_name])
    resource.password = resource.email if resource.password.blank?
    if resource.errors.empty?
      if resource.password == resource.email
        flash[:alert] = "You didn't provide a password, so we've set it to be the same as your email address. You might want to consider changing that in your Profile"
      end
      invitation_event = RpEvent.where(subject_id: resource.invited_by_id, indirect_object_id: resource.id, indirect_object_type: resource.class.to_s).first
      RpEvent.post resource, :invitation_accepted, invitation_event, User.find(resource.invited_by_id)
      RpMailer.welcome_email(resource).deliver
      RpMailer.invitation_accepted_email(resource).deliver
      set_flash_message :notice, :updated
      sign_in(resource_name, resource)
      redirect_to after_accept_path_for(resource), status: 303
    else
      # respond_with_navigational(resource){ dialog_boilerplate :edit }
      respond_with_navigational(resource) { smartrender :action => :edit }
    end
  end

  # When the user gets distracted by the recipe link in a sharing notice
  def divert
=begin
    RpEvent.post 
      resource_class.find(params[:recipient]), 
	:invitation_diverted, 
      nil, 
      resource_class.find(params[:sender])
=end
    redirect_to CGI::unescape(params[:url])
  end

  def after_accept_path_for resource
    defer_welcome_dialogs
    after_sign_in_path_for resource
  end
end
