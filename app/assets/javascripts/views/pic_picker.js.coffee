RP.pic_picker = RP.pic_picker || {}

RP.pic_picker.arm = (event) ->

###
	$(dlog).on 'preload', 'a.pic_picker_golink', ->
###

mylink = () ->
	$('a.pic_picker_golink')

mydlog = () ->
	$('div.dialog.pic_picker')

# Close with save
RP.pic_picker.close = (dlog) ->
	# Transfer the logo URL from the dialog's text input to the page text input

	# The input field points to the originating golink
	targetGolinkSelector = "a#"+$("input.icon_picker").data('golinkid')

	# The golink points to the original image and/or input fields
	linkdata = $(targetGolinkSelector).data()
	url = $("input.icon_picker").attr("value")
	imagePreviewWidgetSet linkdata.imgId, linkdata.inputId, url

	# Finally, clone the dialog and save the clone in the link for later
	clone = dlog.cloneNode true
	$(targetGolinkSelector).data 'preloaded', clone

# Respond to a link by bringing up a dialog for picking among the image fields of a page
# -- the pic_picker div is ready to be a diaog
# -- the data of the link must contain urls for each image, separated by ';'
# formerly PicPicker
RP.pic_picker.open = (dlog) ->
	$('a.image_preview_button').click ->
		previewImg('input.icon_picker', 'div.preview img', '')
		# imagePreviewWidgetSet($('input.icon_picker').attr("value"), 'div.preview img', '')
	return true

# Handle a click on a thumbnail image by passing the URL on to the
# associated input field
RP.pic_picker.make_selection = (url) ->
	$('input.icon_picker').attr "value", url
	previewImg 'input.icon_picker', 'div.preview img', ''
	# imagePreviewWidgetSet 'input.icon_picker', 'div.preview img', ''

