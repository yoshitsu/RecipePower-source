# This is a manifest file that'll be compiled into including all the files listed below.
# Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
# be included in the compiled file accessible from http://example.com/assets/application.js
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
# Place your application-specific JavaScript functions and classes here
# This file is automatically included by javascript_include_tag :defaults

#= require_self
#= require arch/collection.js.coffee
# require ../../../vendor/assets/javascripts/jquery
#= require jquery/jquery.tokeninput
#= require bootbox
#= require history
#= require masonry.pkgd
#= require jquery_ujs

#= require authentication

#= require common/dialog
#= require common/pics
#= require common/RP
#= require common/submit
#= require common/notifications

#= require_directory ./views
#= require_directory ./concerns
# require bootstrap

window.RP = window.RP || {}
