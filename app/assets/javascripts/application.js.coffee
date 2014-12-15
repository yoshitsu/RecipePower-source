# This is a manifest file that'll be compiled into including all the files listed below.
# Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
# be included in the compiled file accessible from http://example.com/assets/application.js
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
# Place your application-specific JavaScript functions and classes here
# This file is automatically included by javascript_include_tag :defaults

# require jquery-1.7.1
#= require_self
#= require collection
#= require_directory ../../../vendor/assets/javascripts/jquery
#= require ../../../vendor/assets/javascripts/JavaScript-Load-Image/load-image.all.min.js
#= require ../../../vendor/assets/javascripts/JavaScript-Canvas-to-Blob/canvas-to-blob.min.js
#= require ../../../vendor/assets/javascripts/jquery/fileupload/jquery.iframe-transport.js
#= require ../../../vendor/assets/javascripts/jquery/fileupload/jquery.fileupload.js
#= require ../../../vendor/assets/javascripts/jquery/fileupload/jquery.fileupload-process.js
#= require ../../../vendor/assets/javascripts/jquery/fileupload/jquery.fileupload-image.js

#= require ../../../vendor/assets/javascripts/imagesloaded.pkgd.min
#= require ../../../vendor/assets/javascripts/bootstrap-filestyle.min
#= require bootbox
#= require history
#= require masonry.pkgd
#= require jquery_ujs

#= require authentication
#= require messaging

# require_directory ./controllers
# require bm
# require errors
# require expressions
# require invitations
# require referents
# require registrations
# require sites

#= require_directory ./common
#= require_directory ./views
#= require_directory ./concerns
# require views/edit_recipe
# require views/pic_picker
# require views/rcp_list

# require injector
# require microformat
# require oldRP
# require rails
# require RPDialogTest
# require RPfields
# require RPquery

#= require bootstrap

window.RP ||= {}
