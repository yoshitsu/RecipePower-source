# Support for editing recipe tags

RP.edit_recipe = RP.edit_recipe || {}

jQuery ->
	RP.edit_recipe.bind()

# Handle editing links
RP.edit_recipe.bind = (dlog) ->
	dlog ||= $('body') # window.document
	# Set up processing for click events on links with a 'edit_recipe_link' class
	$(dlog).on "click", '.edit_recipe_link', RP.edit_recipe.go

me = () ->
	$('div.edit_recipe')[0]

channel_tagger_selector = "div.edit_recipe #recipe_channel_tokens"
collection_tagger_selector = "div.edit_recipe #recipe_collection_tokens"
tagger_selector = "div.edit_recipe #recipe_tagging_tokens"

# Open the edit-recipe dialog on the recipe represented by 'rcpdata'
RP.edit_recipe.go = (evt, xhr, settings) ->
	rcpdata = $(this).data()
	template = $('div.template#tag-collectible')
	dlog = me()
	# If it has children it's active, and should be put away, starting with hiding it.
	if $('.edit_recipe > *').length > 0
		$(dlog).hide()
	# Parse the data for the recipe and insert into the dialog's template.
	# The dialog has placeholders of the form %%rcp<fieldname>%% for each part of the recipe
	# The status must be set by activating one of the options
	if templ = $(template).data "template"
		# ...but then again, the dialog may be complete without a template
		# statustarget = '<option value="'+rcpdata.rcpStatus+'"'
		# statusrepl = statustarget + ' selected="selected"'
		dlgsource = templ.string.
		replace(/%(25)?%(25)?rcpID%(25)?%(25)?/g, rcpdata.rcpid). # May have been URI encoded
		replace(/%%rcpTitle%%/g, rcpdata.rcptitle).
		replace(/%%rcpPicData%%/g, rcpdata.rcppicdata || "/assets/NoPictureOnFile.png" ).
		replace(/%25%25rcpPicData%25%25/g, encodeURIComponent(rcpdata.rcppicdata || "/assets/NoPictureOnFile.png" )).
		replace(/%%rcpPicURL%%/g, rcpdata.rcppicurl || "" ).
		replace(/%25%25rcpPicURL%25%25/g, encodeURIComponent(rcpdata.rcppicurl || "")).
		replace(/%%rcpURL%%/g, rcpdata.rcpurl).
		replace(/%25%25rcpURL%25%25/g, encodeURIComponent(rcpdata.rcpurl)).
		replace(/%%rcpCollectibleUserId%%/g, rcpdata.rcpcollectibleuserid).
		replace(/%%rcpPrivate%%/g, rcpdata.rcpprivate).
		replace(/%%rcpComment%%/g, rcpdata.rcpcomment).
		replace(/%%rcpStatus%%/g, rcpdata.rcpstatus).
		replace(/%%authToken%%/g, rcpdata.authtoken) # .replace(statustarget, statusrepl)
		$(template).html dlgsource # This nukes any lingering children as well as initializing the dialog
	# The tag data is parsed and added to the tags field directly
	# rcpdata.rcpmisctagdata.query = "tagtype_x=11,15&showtype=true&verbose=true"
	RP.tagger.init tagger_selector, rcpdata.rcptagdata # jQuery.parseJSON(rcpdata.rcptagdata)
	$('textarea').autosize()
		
	# Hand it off to the dialog handler
	RP.dialog.run me()
	# When submitting the form, we abort if there's no change
	# Stash the serialized form data for later comparison
	# $('form.edit_recipe').data "before", recipedata $('form.edit_recipe').serializeArray()
	dataBefore = recipedata $('form.edit_recipe', dlog).serializeArray()
	$('form.edit_recipe', dlog).data "hooks", {
		dataBefore: recipedata($('form.edit_recipe', dlog).serializeArray()),
		beforesaveFcn: "RP.edit_recipe.submission_redundant"
	}
	RP.makeExpandingArea $('div.expandingArea', dlog)
	false

# When dialog is loaded, activate its functionality
RP.edit_recipe.onload = (dlog) ->
	dlog = me()
	# Only proceed if the dialog has children
	if $('.edit_recipe > *').length > 0
		# The pic picker is preloaded onto its link element. Unhide the link when loading is complete
		rcpid = $('form.edit_recipe', dlog).attr("id").replace /\D*/g, ''
		if touch_recipe = RP.named_function "RP.rcp_list.touch_recipe"
			touch_recipe rcpid

# Handle a close event: when the dialog is closed, also close its pic picker
RP.edit_recipe.onclose = (dlog) ->
	if picker_dlog = $("div.pic_picker")
		$(picker_dlog).remove();	
	return true # Prevent normal close action
	
# Extract a name from a reference of the form "recipe[<name>]"
recipedata = (arr) ->
	result = new Object()
	$.each arr, ->
		if this.name.match(/recipe\[.*\]$/) 
			index = this.name.replace /^recipe\[(.*)\]/, "$1"
			result[index] = this.value
	result

# Don't submit if nothing has changed
RP.edit_recipe.submission_redundant = (dlog) ->
	# If the before and after states don't differ, we just close the dialog without submitting
	hooks = $('form.edit_recipe', dlog).data "hooks"
	dataBefore = hooks.dataBefore
	dataAfter = recipedata $('form.edit_recipe', dlog).serializeArray()
	for own attr, value of dataAfter
		if dataBefore[attr] != value # Something's changed => do normal forms processing
			return null
	# Nothing's changed => we can just silently close the dialog
	return { done: true, popup: "Sorted! Cookmark secure and unchanged." }
