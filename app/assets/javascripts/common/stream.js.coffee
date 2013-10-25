RP.stream ||= {}

RP.stream.go = (evt) ->
	me = evt.currentTarget
	# Check with the stream generator for content
	kind = $(me).data('kind')
	source = new EventSource "/stream/stream?kind="+kind
	source.addEventListener 'end_of_stream', (e) ->
		source.close()
	source.addEventListener 'stream_item', (e) ->
		jdata = JSON.parse e.data
		# If the item specifies a handler, call that
		if handler = jdata.handler && fcn = RP.named_function
			fcn.apply jdata
		else # Standard handling: append to a parent designated by selector
			item = $(jdata.elmt)
			selector = jdata.selector || '.collection_list'
			$(selector).append item
			if selector == '#masonry-container'
				$('#masonry-container').masonry 'appended', item
		
RP.stream.buffer_test = ->
	source = new EventSource('/stream/buffer_test')
	source.addEventListener 'end_of_stream', (e) ->
		source.close()
	source.addEventListener 'message', (e) ->
		jdata = JSON.parse e.data
		$('#masonry-container').append("<div>"+jdata.text+"</div>")

