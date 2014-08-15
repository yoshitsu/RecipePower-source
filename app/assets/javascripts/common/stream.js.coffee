RP.stream ||= {}

jQuery ->
	$(window).scroll () ->
		RP.stream.check()
	RP.stream.check()

RP.stream.check = (elmt) ->
	if elmt = RP.findWithin( 'a.stream-trigger', elmt)
		rect = elmt.getBoundingClientRect()
		if rect && (rect.bottom-rect.height) <= $(window).height()
			RP.stream.fire elmt

# Event-driven interface, an onload handler
RP.stream.go = (evt) ->
	RP.stream.fire evt.target

RP.stream.fire = (elmt) ->
	elmt.innerHTML = "Recipes are on their way..."
	querypath = $(elmt).data('path')
	container_selector = $(elmt).data('containerSelector') || ""
	$(elmt).remove() # Remove the link element to forestall subsequent loads
	# It will be replaced when the trigger div gets replaced
	container_selector += " .stream-items-parent"
	source = new EventSource querypath
	source.onerror = (evt) ->
		source.close()
		state = evt.target.readyState
	source.addEventListener 'end_of_stream', (e) ->
		jdata = JSON.parse e.data
		source.close()
		if jdata.more_to_come
			RP.collection.more_to_come jdata.more_to_come
		RP.process_response jdata
	source.addEventListener 'stream_item', (e) ->
		jdata = JSON.parse e.data
		# If the item specifies a handler, call that
		if handler = jdata.handler && fcn = RP.named_function
			fcn.apply jdata
		else # Standard handling: append to the seeker_table
			item = $(jdata.elmt)
			# selector = jdata.selector || '.collection_list'
			# $(selector).append item
			$(container_selector).append item
			if $(container_selector).hasClass 'js-masonry'
				masonry_selector = container_selector+'.js-masonry'
				$(masonry_selector).masonry 'appended', item
				# Any (hopefully few) pictures that are loaded from URL will resize the element
				# when they appear.
				$(item).on 'resize', (evt) ->
					$(masonry_selector).masonry()
				RP.rcp_list.onload $('div.collection-item',item)

RP.stream.buffer_test = ->
	source = new EventSource('/stream/buffer_test')
	source.addEventListener 'end_of_stream', (e) ->
		source.close()
	source.addEventListener 'message', (e) ->
		jdata = JSON.parse e.data
		$('#seeker_results').append("<div>"+jdata.text+"</div>")
