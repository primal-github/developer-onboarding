#!/usr/bin/env ruby
 
# Load in the PrimalAccess class
require './PrimalAccess.rb'
require 'rubygems'
 
# We require this particular gem
#
# To install it:
#   gem install json
#
require 'json'
 
# Prints things out nicely
require 'pp'
 
# Constructs the PrimalAccess object so we can talk to Primal
primal = PrimalAccess.new("<your appId>", "<your appKey>",
                          "<your username>", "<your password>")
 
#
# Here's the important part.  We specify the @Interests source in
# in order to specify that we only want the topics of interest in
# the response payload.  We will not be retrieving any filtered
# content at all.
#
code, body = primal.postThenFilter("/travel/adventure")
 
#
# Just show the topics of interest.
#
def processJSON(json)
  # "Pretty Print" the JSON response
  pp json
end
 
# If successful
if code == 200
  # Convert the payload to JSON
  json = JSON.parse(body)
  # Process the result
  processJSON(json)
else
  puts "Something went wrong #{code} -- #{body}"
end
