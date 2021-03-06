# Generic dialog management
RP.dialog = RP.dialog || {}

# Handle 'dialog-run' remote links
jQuery ->
	# $(document).on("ajax:beforeSend", '.dialog-run', RP.dialog.beforeSend)
	# $(document).on("ajax:success", '.dialog-run', RP.dialog.success)
	# $(document).on("ajax:error", '.dialog-run', RP.dialog.error)
	$(document).on 'shown.bs.modal', (event) ->
		# When a dialog is invoked, focus on the first autofocus item, or a string item or a text item
		$('[autofocus]:first', event.target).focus()[0] ||
		$('input.string', event.target).focus()[0] ||
		$('input.text', event.target).focus()[0]

RP.dialog.close = (event) ->
	if event
		if dlog = RP.dialog.target_modal(event)
			event.preventDefault()
		else
			return true # Do regular click-handling, presumably returning from whence we came
	else
		dlog = $('div.dialog')[0]
	close_modal dlog, "close"

###
  RP.dialog.cancel = (event) ->
      # Ask the server for any subsequent popups or a Done flag to close
      RP.submit.submit_and_process "http://local.recipepower.com:3000/popup"
  	if event
		if dlog = RP.dialog.target_modal(event)
			event.preventDefault()
		else
			return true # Do regular click-handling, presumably returning from whence we came
	else
		dlog = $('div.dialog')[0]
	# RP.dialog.close_modal dlog
	close_modal dlog, "cancel"
###

# Take over a previously-loaded dialog and run it
RP.dialog.run = (dlog) ->
	open_modal dlog, true

# Insert a new modal dialog while saving its predecessor
RP.dialog.push_modal = (newdlog, odlog) ->
	odlog ||= RP.dialog.enclosing_modal()
	newdlog = insert_modal newdlog, odlog # Insert the new dialog into the DOM
	push_modal newdlog, odlog # Hide, detach and store the parent with the child
	open_modal newdlog

# Insert a new modal dialog, closing and replacing any predecessor
RP.dialog.replace_modal = (newdlog, odlog) ->
	odlog ||= RP.dialog.enclosing_modal()
	newdlog = insert_modal newdlog, odlog
	if odlog && newdlog && (odlog != newdlog) # We might be just reopening a retained dialog
		close_modal odlog, "cancel"
	if newdlog
		open_modal newdlog
	newdlog

# Remove the dialog and notify its handler prior to removing the element
RP.dialog.close_modal = (dlog, epilog) ->
	close_modal dlog
	RP.notifications.post epilog, "popup"
	# If there's another dialog or recipe to edit waiting in the wings, trigger it
	RP.fire_triggers()

# Public convenience methods for handling events
RP.dialog.onopen = (dlog, entity) ->
	notify 'open', dlog, entity

RP.dialog.onclose = (dlog, entity) ->
	notify 'close', dlog, entity

RP.dialog.onload = (dlog, entity) ->
	notify 'load', dlog, entity

RP.dialog.onsave = (dlog, entity) ->
	notify 'save', dlog, entity

# ------------ Thus ends the public interface. Private methods: ------------------

# From a block of code (which may be a whole HTML page), extract a
# modal dialog, attach it relative to a parent dialog, and return the element
insert_modal = (newdlog, odlog) ->
	if typeof newdlog == 'string'
		# Assuming the code is a fragment for the dialog...
		wrapper = document.createElement('div');
		wrapper.innerHTML = newdlog;
		newdlog = wrapper.firstElementChild
		if $(newdlog).hasClass('dialog')
			wrapper.removeChild newdlog
		else
			# ...It may also be a 'modal-yield' dialog embedded in a page
			# dom = $(newdlog)
			# if newdlog = $('div.dialog', dom)[0]
			# return $(newdlog, dom).detach()[0]
			# else if $(dom).hasClass "dialog"
			# $(dom).removeClass('modal-pending').addClass('modal')
			# return dom[0]
			doc = document.implementation.createHTMLDocument("Temp Page")
			doc.open()
			doc.write newdlog
			doc.close()
			# We extract dialogs that are meant to be opened instead of the whole page
			newdlog = $('div.dialog.modal-yield', doc.body).removeClass("modal-yield").addClass("modal-pending").detach()[0]
	# Now the dialog is a detached DOM elmt: attach it relative to the parent
	if odlog && (odlog != newdlog) && odlog.parentNode # We might be just reopening a retained dialog
		odlog.parentNode.insertBefore newdlog, odlog
		newdlog = odlog.previousSibling
	# Add the new dialog at the end of the page body if necessary
	if !newdlog.parentNode
		newdlog = document.getElementsByTagName("body")[0].appendChild newdlog
	newdlog

# Return the dialog element for the current event target, correctly handling the event whether
# it's a jQuery event or not
RP.dialog.target_modal = (event) ->
	RP.dialog.enclosing_modal RP.event_target(event)

# Return the dialog in which the given element may be found, or any old modal if no element
RP.dialog.enclosing_modal = (elmt) ->
	dlogs = $('div.dialog.modal')
	if elmt
		for dlog in dlogs
			if $(elmt, dlog)[0]
				return dlog
		return null
	else
		return dlogs[0]

open_modal = (dlog, omit_button) ->
	if (onget = $(dlog).data "onget" ) && (fcn = RP.named_function "RP." + onget.shift() )
		fcn.apply null, onget
	RP.hide_all_empty()
	show_modal dlog # $(dlog).removeClass('modal-pending').removeClass('hide').addClass('modal')
	notify "load", dlog
	RP.state.onDialogOpen dlog
	if !(omit_button || $('button.close', dlog)[0])
		buttoncode = '<button type=\"button\" class=\"close dialog-x-box dialog-cancel-button\" data-dismiss=\"modal\" aria-hidden=\"true\">&times;</button>'
		$('div.modal-header', dlog).prepend buttoncode
	if $(dlog).modal
		$(dlog).modal()
	if $('input:file.directUpload')[0]
		uploader_unpack()
	notify "open", dlog
	notify_injector "open", dlog
	$('.token-input-field-pending', dlog).each ->
		RP.tagger.setup this
	# Arm event responders for the dialog
	if typeof RP.submit != 'undefined' # The submit module has its own onload call, so we only call for new dialogs
		RP.submit.bind dlog # Arm submission links and preload sub-dialogs
	$('.dialog-cancel-button', dlog).click (event) ->
		# When canceling, check for pending dialog/page, following instructions in the response
		dlog = event.target
		if !$(dlog).hasClass "cancelled"
			$(dlog).addClass "cancelled"
			RP.submit.submit_and_process "/popup"
		event.preventDefault()
	$('a.question_section', dlog).click RP.showhide
	if requires = $(dlog).data 'dialog-requires'
		for requirement in requires
			if fcn = RP.named_function "RP." + requirement + ".bind"
				fcn.apply()
	RP.fire_triggers()
	dlog

hide_modal = (dlog) ->
	if $(dlog).modal
		$(dlog).modal 'hide'
	else
		$(dlog)
	$(dlog).addClass('hide').removeClass("modal").addClass 'modal-pending'

show_modal = (dlog) ->
	$(dlog).removeClass('hide').addClass('modal').removeClass 'modal-pending'
	if $(dlog).modal
		$(dlog).modal 'show'

# The following pair push and pop the dialog state
# 'push' detaches the parent dialog and stores it in the child's data
push_modal = (dlog, parent) ->
	hide_modal parent
	$(parent).detach()
	$(dlog).data("parent", parent)

# Remove the child dialog, notifying it of the action, and reopen the parent
# The parent was stored in the child's data
pop_modal = (dlog, action) ->
	hide_modal dlog
	if parent = $(dlog).data "parent"
		insert_modal parent, dlog
		notify action, dlog
		show_modal parent
	else
		notify action, dlog
		$('div.modal-backdrop').remove()

close_modal = (dlog, action) ->
	if dlog
		pop_modal dlog, (action || "close") # Modal can either be closed or cancelled
		RP.state.onCloseDialog dlog
		if !$(dlog).hasClass 'keeparound'
			$(dlog).remove()
		notify_injector "close", dlog

# Filter for submit events, ala javascript. Must return a flag for processing the event normally
filter_submit = (eventdata) ->
	context = this
	dlog = eventdata.data
	clicked = $("input[type=submit][clicked=true]")
	# return true;
	if ($(clicked).attr("value") == "Save") && (shortcircuit = notify "beforesave", dlog, eventdata.currentTarget)
		close_modal dlog, "cancel"
		eventdata.preventDefault()
		RP.process_response shortcircuit
	else
		# Okay to submit
		if (confirm_msg = $(clicked).data 'confirmMsg') && !confirm(confirm_msg)
			return false
		if wait_msg = $(clicked).data('waitMsg')
			RP.notifications.wait wait_msg
		# To sort out errors from subsequent dialogs, we submit the form synchronously
		#  and use the result to determine whether to do normal forms processing.
		method = $(clicked).data("method") || $('input[name=_method]', this).attr "value"
		$(context).ajaxSubmit
			url: $(clicked).data("action") || context.action,
			type: method, # $('input[name=_method]', this).attr("value"),
			async: false,
			dataType: 'json',
			error: (jqXHR, textStatus, errorThrown) ->
				RP.notifications.done()
				jsonout = RP.post_error jqXHR, dlog # Show the error message in the dialog
				eventdata.preventDefault()
				return !RP.process_response jsonout, dlog
			success: (responseData, statusText, xhr, form) ->
				RP.notifications.done()
				RP.post_success responseData, dlog, form
				eventdata.preventDefault()
				sorted = RP.process_response responseData, dlog
				if responseData.success == false
					# Equivalent to an error, so just return
					return sorted
	return false

manager_of = (dlog) ->
	# Look for a manager using the dialog's class name
	if dlog
		if mgr_name = $(dlog).data 'manager'
			return RP[mgr_name]
		if classname = $(dlog).attr 'class'
			classList = classname.
			replace(/\b(modal|dialog)\b/g, ''). # Ignore 'modal', etc.
			replace(/^\s*/,'').  # Eliminate whitespace fore and aft
			replace(/\s*$/,'').
			replace(/-/g, '_'). # Translate hyphen for a legitimate function name
			split /\s+/
			for mgr_name in classList
				if RP[mgr_name]
					return RP[mgr_name]
	return null

# Determine either the callback (kind = "Fcn") or the message (kind="Msg")
#  for a given event type from among:
# load
# beforesave
# save
# cancel
# close
# If there's a function for the event in the hooks, call it
# If it doesn't exist, or returns false when called, and there's a message for the event in the hooks, post it
# If it doesn't exist, or returns false when called, and there's a handler for the manager of the dialog, call it
# If it doesn't exist, or returns false when called, apply the default event handler 
notify = (what, dlog, entity) ->
	hooks = $(entity || dlog).data("hooks");
	fcn_name = what + "Fcn";
	msg_name = what + "Msg";
	# If the entity or the dialog have hooks declared, use them
	if hooks
		if hooks.hasOwnProperty msg_name
			RP.notifications.post hooks[msg_name], "popup"
		if hooks.hasOwnProperty fcn_name
			fcn = RP.named_function hooks[fcn_name]
			return fcn dlog # We want an error if the function doesn't exist

	# If there's a manager module with a responder, call it
	if (mgr = manager_of dlog) && (fcn = mgr[what] || mgr["on" + what])
		fcn dlog

	# Otherwise, run the default
	switch what
		when 'load', 'onload'
			$('[onload]', dlog).trigger 'load'
		when "open", "onopen"
		# onopen handler that sets a Boostrap dialog up to run modally: Trap the
		# form submission event to give us a chance to get JSON data and inject it into the page
		# rather than do a full page reload.
			show_modal dlog
			$(dlog).on 'shown', ->
				$('textarea', dlog).focus()
			# Forms submissions that expect JSON structured data will be handled here:
			$('form', dlog).submit dlog, filter_submit
			# Turn a Bootstrap button group into radio buttons
			$("form input[type=submit]").click ->
				# Here is where we enable multiple submissions buttons with different routes
				# The form gets 'data-action', 'data-method' and 'data-operation' fields to divert
				# forms submission to a different URL and method. (data-operation declares the purpose
				# of the submit for, e.g., pre-save checks)
				$("input[type=submit]", dlog).removeAttr "clicked"
				$(this).attr "clicked", "true"
			$('div.btn-group').each ->
				group = $(this);
				if name = group.attr 'data-toggle-name'
					form = group.parents('form').eq(0);
					hidden = $('input[name="' + name + '"]', form);
					$('button', group).each ->
						button = $(this);
						if button.val() == hidden.val()
							button.addClass 'active'
						button.live 'click', ->
							if $(this).hasClass "active"
								hidden.val $(hidden).data("toggle-default")
								$(this).removeClass "active"
							else
								hidden.val $(this).val()
								$('button', group).each ->
									$(this).removeClass "active"
								$(this).addClass "active"
	return
###
	#	when "load", "onload"
	# when "beforesave"
	# when "save", "onsave"
	# when "cancel", "oncancel"
	# when "close", "onclose"
	return
###

# Special handler for dialogs imbedded in an iframe. See 'injector.js'
notify_injector = (what, dlog) ->
	if fcn = RP.named_function what + "_dialog"
		fcn dlog

