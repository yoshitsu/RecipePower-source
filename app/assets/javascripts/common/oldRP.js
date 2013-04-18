/* Master function for assigning actions to interface items */
$(document).ready(function() { //wait for the dom to load
}); 

$(function() {
	/* Respond to a click on the "Absorb" button accompanying a redundant tag.
	  The response is to fire off a merge request from the server, which 
	  sends back a list of DOM elements to delete, which we handle with the 
	  function nuke_DOM_elements_by_id.
	*/
	$('.absorb_button').click( function(event) {
		var source_id = get_id_from_element($(this))
		var target = $(this).closest('tr')
		var target_id = get_id_from_element(target)
		jQuery.get("tags/"+target_id+"/absorb",
					{ victim: source_id },     
					nuke_DOM_elements_by_id,
					"json");		
		
	})
	/* Respond to the selection of a different tag type by getting a new
	 * page based on the new type.
	 */
	$('#taglist_type_selector').change( function(event) {
		var newtype = $(this)[0].value
		jQuery.get("tags", 
			{ tagtype: newtype }, 
			function(body, status, instance) { if(status=="success") { $("body").html(body) } }, 
			"html"
		)
	})
	$('.tag_type_selector').change(function(event) {
		// We're operating on the nearest table row element
		var element = $(this).closest('tr')
		//...which has the id of the tag to change
		var tagid = get_id_from_element(element)
		var node = element[0]
		var nextel = element.next()[0]	// The hr element too
		// Our good old popup here has the new type of the tag
		var value = $(this)[0].value
	    // Fire off an Ajax call notifying the server of the (re)classification
	    jQuery.get("/tags/typify",
				    {
				        tagid: tagid,
						newtype: value
				    },
					nuke_DOM_elements_by_id,
				    "json");
	})
    $("#Focus_on_tags").tokenInput("/tags/match.json", {
        crossDomain: false,
        hintText: "", // "Type tags and strings to look for",
		noResultsText: "No matching tag found; hit Enter to search with text",
        prePopulate: "", 
        theme: "facebook",
        onAdd: editAnotherTag,
        onDelete: tokenChangeCallback,
        allowFreeTagging: true // allowCustomEntry: true
    });
	$('.remove_fields').click(function(event) {
	    $(this).prev('input[type=hidden]').val('1')
	    $(this).closest('tr').hide()
	    event.preventDefault()
	});
	/*
	$('form').on 'click', '.add_fields', (event) ->
	    time = new Date().getTime()
	    regexp = new RegExp($(this).data('id'), 'g')
	    $(this).before($(this).data('fields').replace(regexp, time))
	    event.preventDefault()
	*/
});

// Callback to select another tag for editing
function editAnotherTag(hi, li) {
	if (hi && hi.id) {
		$('body').load( "/tags/"+hi.id+"/edit" );
	}
}

/* Utility function to extract an integer key which terminates the
   id of some ancestor of 'start', given by 'spec'
*/
function get_id_from_element(element) {
	var regexp = new RegExp(".*_", "g")
	return element.attr('id').replace(regexp, "")
}

function nuke_DOM_elements_by_id(body, status, instance) {
    // Use the returned IDs to remove the entries from the list
    // First, generate a query string for jQuery from the returned ids
    // var refstr = body.map(function(elmt, ix, arr) { return "#" + elmt; }).join(',');
    // $(refstr).remove();
    // Could be adding the strings to the target tab, if it's loaded
	if(status == "success") {
		if(list = body['to_nuke']) {
			// With success, the body is an array of descriptors for nuking
			list.forEach(function(item) { 
				$(item).remove()
			 });			
		}
	}
}

function merge_tags(event) {
	// Shouldn't get here
	return true;
}

function getWdwData() {
	var tabindex = $("#tags_tabset").tabs('option', 'selected');
	return {
		tabindex: tabindex,
		tagListSelector: "#taglist"+tabindex,
		referentTreeSelector: "#referenttree"+tabindex,
		listTextElement: "#tag_entry"+tabindex
	}
}

// Here's how to setup a wrapper method:
(function($){
  $.fn.mycheck = function() {
	var val = $("#tags_tabset").tabs('option', 'selected');
    return 1;
  };
})(jQuery);

// Check that the images in a window have been loaded, fitting them into
// their frames when the size is available. NB: It's best to restrict this set to
// the visible images, for performance's sake.
/*
function wdwFitImages(selection) {
    var TO = window.setInterval(function() {
        var allDone = true;
		if(arguments.length == 0) {
			selection = $("img.fitPic");
		} else {
			if (selection.ELEMENT_NODE) {
				selection = $("img.fitPic", selection);
			} else {
				selection = selection.find("img.fitPic");
			}
		}
        selection.each(function() {
            allDone = fitImage(this) && allDone;
        });
        if (allDone) {
            window.clearInterval(TO);
        }
    },
    10);
}
*/

// NOT YET GUARANTEED
// Responder for link to return to the user's list
function backToMe(uid) {
    var x = 2;
}

function alertIframeSelection() {
    var iframe = document.getElementById("viewframe");
    alert(getIframeSelectionText(iframe));
};

function alertSelectionText() {
    var editor_body = self.window.document;
    var range;

    if (editor_body.getSelection()) {
        range = editor_body.getSelection();
        alert(range.toString());
    } else if (editor_body.selection.createRange()) {
        range = editor_body.selection.createRange();
        alert(range.text);
    } else return;
}

function makeIframeSelectionRed() {
    var editor_body = self.window.document;
    var range;

    if (editor_body.getSelection()) {
        range = editor_body.getSelection();
    } else if (editor_body.selection.createRange()) {
        range = editor_body.selection.createRange();
    } else return;
    range.pasteHTML("<span style='color: red'>" + range.htmlText + "</span>");

    // var range = document.getElementById("myid").contentWindow.document.selection.createRange();
    // range.pasteHTML("<span style='color: red'>" + range.htmlText + "</span>");
}

function remove_fields(link) {
    $(link).prev("input[type=hidden]").val("1");
    $(link).closest(".fields").hide();
    queryformHit($("form")[0], {});
}

function add_fields(link, association, content) {
    var new_id = new Date().getTime();
    var regexp = new RegExp("new_" + association, "g")
    $(link).parent().before(content.replace(regexp, new_id));
}

// Take an HTML element from the server and replace it in the DOM
function replaceElmt(body, status, instance) {
	if(status == "success") {
		var selector = body.selector
		var content = body.content
		$(selector).replaceWith(content);
	}
}

function boostInTablist(list_element_class, list_element_body, targettab) {
    // Insert the resulting element at the top of the All Cookmarks tab, if open
    var tabid = $("#rcpquery_tabset").tabs("option", "selected");
    if(tabid==targettab) {
	  $("#rcplist_mine_body ."+list_element_class).remove()
	  $("#rcplist_mine_body").prepend(list_element_body);
    }
}

// Request the server to add a recipe to a user's collection, allowing for an 
function rcpCollect(id) {
  // Call server on /recipes/:id/collect
  jQuery.get( "/recipes/"+id+"/collect", {},
    function(data, status, hr) {
	  if(status == "success") {
		if(data.type == "dialog") {
			$("#container").append(data.body);
			$('form').submit( function(eventdata) { // Supports multiple forms in dialog
				$.ajax({
			        url: eventdata.srcElement.action,
			        type: 'post',
			        dataType: 'json',
			        data: $(eventdata.srcElement).serialize()
			    });
			})
			$("div.sign_in").dialog({
				modal: true,
				width: 900,
				title: "Let's get you signed in so we can do this properly",
			});			
		} else if(data.type == "element") { // Successful (non-redirected) response from server
		    $("."+data.go_link_class).replaceWith(data.go_link_body);
		    boostInTablist(data.list_element_class, data.list_element_body, 3) // Put it at the top of My Cookmarks
		    boostInTablist(data.list_element_class, data.list_element_body, 4) // Put it at the top of the Recent tab
		    $("div.ack_popup").text(data.title);
		    RP.notifications.post( "Got it! Now appearing at the top of My Cookmarks.", "popup");
		} else if(data.type == "error" ) {
		    RP.notifications.post( "Sorry, couldn't grab cookmark: "+data.error, "popup");
		}
	  }
    }, "json" );
}

function rcpAdd() { // Add a recipe to the cookmarks by pasting in a URL
  jQuery.get( "/recipes/new", {},
    function(data, status, hr) {
	  if(status == "success") {
		if(data.dialog != null) {
			runModalDialog(data.dialog );
		} else if(data.type == "element") { // Successful (non-redirected) response from server
		    $("."+data.go_link_class).replaceWith(data.go_link_body);
		    boostInTablist(data.list_element_class, data.list_element_body, 3) // Put it at the top of My Cookmarks
		    boostInTablist(data.list_element_class, data.list_element_body, 4) // Put it at the top of the Recent tab
		    $("div.ack_popup").text(data.title);
		    RP.notifications.post( "Got it! Added to collection and now appearing at the top of My Cookmarks.", "popup");
		}
	  }
  }, "json" );
}

/*
// Called when the tag tabs load to set up dynatree, etc.
function tagTabsOnLoad(event, info) {
    var TO = window.setInterval(function() {
        var idselector = "#tag_entry" + info.index;
        // var source = '/tags/match?morph=strings&tabindex=' + info.index;
        // var source = '/tags.json';
        if ($(idselector).length > 0) {
            // $(idselector).autocomplete({source:source, search:tagTabsTakeTyping})
            $(idselector).bind('change', tagTabsTakeTyping);
            $(idselector).bind('keypress', tagTabsTakeTyping);
            $(idselector).bind('input', tagTabsTakeTyping);
            window.clearInterval(TO);
        }
		setupDynatree();
    },
    100);
 	// treatOrphanTags();
    // , helper:"clone"
    $(".tag_tab").droppable({
        drop: tagTabTakeDropFromDynatree,
        hoverClass: "dropGlow",
        tolerance: "pointer"
    });
}

function tagTabTakeDrop(event, info) {
    var drug = info.draggable;
    drug = $(".ui-draggable-dragging");
    // First thing is, collect an array of ids for the dragged elements
    var ids = [];
    var id;
    drug.each(function() {
        var id;
        if (id = (this.getAttribute("id"))) {
            ids.push(id);
        }
    });
    if (ids.length < 1) {
        return;
    }

    // Now get the index of the tab being dropped upon
    var hit = $(this);
    var parent = $(this).parent();
    var children = parent.children();
    var toIndex = $.inArray(this, children);

    // By the way, what tab is active now?
    var fromIndex = $("#tags_tabset").tabs('option', 'selected');

    // Fire off an Ajax call notifying the server of the (re)classification
    jQuery.get("/tags/typify",
    {
        fromtabindex: fromIndex,
        totabindex: toIndex,
        tagids: ids
    },
    function(body, status, instance) {
        // Use the returned IDs to remove the entries from the list
        // First, generate a query string for jQuery from the returned ids
        var refstr = body.map(function(elmt, ix, arr) { return "#" + elmt; }).join(',');
        $(refstr).remove();
        // Could be adding the strings to the target tab, if it's loaded
    },
    "json");
}

function tagTabTakeDropFromDynatree(event, info) {
    var drug = info.draggable;
    drug = $(".ui-draggable-dragging");
    // First thing is, collect an array of ids for the dragged elements
    var ids = [];
    var id;
	var dtNode = $(drug[0]).data("dtSourceNode")
	ids[0] = dtNode.data.key

    // Now get the index of the tab being dropped upon
    var hit = $(this);
    var parent = $(this).parent();
    var children = parent.children();
    var toIndex = $.inArray(this, children);

    // By the way, what tab is active now?
    var fromIndex = $("#tags_tabset").tabs('option', 'selected');

	dtNode.remove();
    // Fire off an Ajax call notifying the server of the (re)classification
    jQuery.get("/tags/typify",
    {
        fromtabindex: fromIndex,
        totabindex: toIndex,
        tagids: ids
    },
    function(body, status, instance) {
        // Use the returned IDs to remove the entries from the list
        // First, generate a query string for jQuery from the returned ids
        // var refstr = body.map(function(elmt, ix, arr) { return "#" + elmt; }).join(',');
        // $(refstr).remove();
        // Could be adding the strings to the target tab, if it's loaded
		var wdwData = getWdwData(); // Get structure containing tabindex, listid and treeid names
		$(wdwData.listTextElement).focus();
    },
    "json");
}

// Respond to typing into the search box: hit the server for a list of matching keys
//  tabindex: index of this tab on the tags page
//  typing: the string typed thus far
//	makeormatch: used to force existence of this exact key
//  url: http string used to hit the server

function tagTabsTakeTyping(event, info) {
    // Send current string to server
    // Get back replacement list of keys
    var id = event.srcElement.id;
    // var tabindex = id.match(/(\D*)(\d*)$/)[2];
    // Tab's index ends the id string
    // var taglistSelector = "#taglist" + tabindex;
    var typing = event.srcElement.value;
    var makeormatch = (event.type == "change") && ($(this).attr("lastCharTyped") == 13);
	// For keypress events, just record the last character typed, for future reference
	if(event.type == "keypress") {
		$(this).attr("lastCharTyped", event.keyCode);
		return;
	}
	// Get structure containing tabindex, listid and treeid names
	var wdwData = getWdwData(); 
	// Reload the dynatree to reflect the typed string
	$(wdwData.tagListSelector).dynatree("option", 
		"initAjax", {
			   url: "/tags/match",
               data: {
					tabindex: wdwData.tabindex,
					unbound_only: true,
					response_format: "dynatree",
					term: typing,
					makeormatch: makeormatch
               }
    });
	var tree = $(wdwData.tagListSelector).dynatree("getTree");
	tree.reload();
	/*
	var resp = jQuery.get(
		"/tags/match",
	    {
	        tabindex: tabindex,
	        term: typing,
	        makeormatch: makeormatch
	    },
	    function(body, status, instance) { 
			$(taglistSelector).replaceWith(body); 
			treatOrphanTags();
		},
	    "html"
	    );
	* /
}

function setupDynatree() {
	// $(".taglist").mycheck();
	
	var wdwData = getWdwData(); // Get structure containing tabindex, listid and treeid names
	$(wdwData.tagListSelector).dynatree({
	    initAjax: {url: "/tags/match",
	               data: {
						  tabindex: wdwData.tabindex,
						  unbound_only: true,
						  response_format: "dynatree"
	                      }
	               },
		autoFocus: false, // So's not to lose focus upon text input
	    dnd: {
	      onDragStart: function(node) {
	        /** This function MUST be defined to enable dragging for the tree.
	         *  Return false to cancel dragging of node.
	         * /
	        logMsg("tree.onDragStart(%o)", node);
	        if(node.data.isFolder)
	          return false;
	        return true;
	      },
	      onDragStop: function(node) {
	        logMsg("tree.onDragStop(%o)", node);
	      }
	    }		
	});
    $(wdwData.referentTreeSelector).dynatree({	
	    initAjax: {url: "/referents",
	               data: {key: 0, // Optional arguments to append to the url
	                      mode: "all"
	                      }
	               },
        onActivate: function(node) {
            // A DynaTreeNode object is passed to the activation handler
            // Note: we also get this event, if persistence is on, and the page is reloaded.
            alert("You activated " + node.data.title);
        },
	    onLazyRead: function(node){
	        node.appendAjax({url: "/referents",
	                           data: {"key": node.data.key, // Optional url arguments
	                                  "mode": "all"
	                                  }
	                          });
	    },
        dnd: {
            onDragStart: function(node) {
                /** This function MUST be defined to enable dragging for the tree.
                 *  Return false to cancel dragging of node.
                 * /
                logMsg("tree.onDragStart(%o)", node);
                return true;
            },
	        autoExpandMS: 300, // Expand nodes after n milliseconds of hovering.
	        preventVoidMoves: true, // Prevent dropping nodes 'before self', etc.
			onDragEnter: function(targetNode, sourceNode) {
				logMsg("tree.onDragEnter(%o)", sourceNode);
				return true;
			},
            onDrop: function(node, sourceNode, hitMode, ui, draggable) {
                /** This function MUST be defined to enable dropping of items on
                 * the tree.
                 * /
				/* We're dropping a node from either the tag list or the tree itself.
				   If the source is the tag list, we send JSON to create a new referent
					to drop into place.
				   If the source is the tree itself, we send JSON to relocate the referent
					in the hierarchy.
				* /
                logMsg("tree.onDrop(%o, %o, %s)", node, sourceNode, hitMode);
				var sourceTreeName = sourceNode.parent.tree.divTree.className;
				var nodeTreeName = node.parent.tree.divTree.className;
				var wdwData = getWdwData(); 
				if(sourceTreeName == nodeTreeName) {
					// Notify the server of the change in hierarchy
					function catchReferent( xhr, status ) {
						if(status == "success") {
							sourceNode.move(node, hitMode);
						}
					}
				  	$.ajax({
							type:"POST",
							url:"/referents/"+sourceNode.data.key,
							data: {_method:'PUT', referent: {parent_id: node.data.key, mode:hitMode, tabindex:wdwData.tabindex }},
							dataType: 'json',
							complete: catchReferent
						});
				} else {
					/* In moving a tag into the referent tree, we're either dropping the tag ONTO a referent
					    (making it an expression for the ref), or dropping it somewhere in the tree. The former
					    is denoted by a hitMode of "over".
					 need to go back to the
						server to 1) notify it of the new referent, and 2) get the referent
						key for inserting into the tree.
					  # POST /referents.json??tagid=1&mode={over,before,after}&target=referentid
					* /
					function catchReferent(response, status, xhr) {
						if(status == "success") {
							if(response[0].key > 0) { // 0 key means no new node
								var copynode = sourceNode.toDict(true, function(dict){
								  // dict.title = "Copy of " + dict.title;
								  // delete dict.key; // Remove key, so a new one will be created
								});
								copynode.key = response[0].key;
						        if(hitMode == "after"){
						          // Append as child node
						          node.addChild(copynode);
						          // expand the drop target
						          node.expand(true);
						        }else if(hitMode == "before"){
						          // Add before this, i.e. as child of current parent
						          node.parent.addChild(copynode, node);
								  node.parent.reloadChildren()
						        }
							} else {
								// Didn't create new node b/c we just dropped term onto it
								// Redraw the target node to reflect changes
								node.setTitle(response[0].title);
							}
			                sourceNode.remove();
				        }
					}
				  	$.post("/referents",
						{tagid:sourceNode.data.key, mode:hitMode, target:node.data.key, tabindex:wdwData.tabindex },
						catchReferent,
						"json");
				}
            }
        },
        persist: true
    });
}

function add_rating(link, association, content) {
    // Get the selected option
    var opts = link.options;
    var selection_ix;
    for (var i = 0; i < opts.length; i++) {
        if (opts[i].selected) {
            selection_ix = i;
        }
    }
    // We expect to get the scale's ID to initialize the fields
    var scale_id_sub = new RegExp("rating_scale_id", "g")

    var rating_id_sub = new RegExp("new_" + association, "g")
    var rating_id = new Date().getTime();

    var name_sub = new RegExp("rating_rname", "g")
    var minlabel_sub = new RegExp("rating_minlabel", "g")
    var maxlabel_sub = new RegExp("rating_maxlabel", "g")

    var labels = opts[selection_ix].title.split(" to ");
    var scalename = opts[selection_ix].text;
    var scale_minlabel = labels[0];
    var scale_maxlabel = labels[1];
    // Substitute labels for the rating, then deploy the scale
    $(link).after(content.
    replace(rating_id_sub, rating_id).
    replace(name_sub, scalename).
    replace(minlabel_sub, scale_minlabel).
    replace(maxlabel_sub, scale_maxlabel).
    replace(scale_id_sub, opts[selection_ix].value));
    // The chosen value
    opts[selection_ix] = null;
    var radbtns = $('input[id^=\'rcpquery_ratings_attributes\']');
    $('input[id^=\'rcpquery_ratings_attributes\']').change(queryChange);
    // if(link.options.length < 2) {
    // Once the last rating is selected and deployed,
    // change the prompt and deactivate the control
    // opts[0].prompt = "No more scales to add";
    // }
}

/* Respond to a click on the recipe-preview button by sending a touch-recipe
   message to the server * /
$('.popup').bind('click', function () {
	return true;
   var popUp = window.open($(this).attr('href'), 'googleWindow',
   'width=600, height=300, scrollbars, resizable');
   if (!popUp || typeof(popUp) === 'undefined') {
      return true;
   } else {
     popUp.focus();
     return false;
   }
});
*/

