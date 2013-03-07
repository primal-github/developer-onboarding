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
# We've made this a separate function because it's going to be what we're going
# to be modifying most often.  The data service will return to us a JSON payload
# as a regular order of business.  What's going to change is how we manipulate
# that result.  This example does very little.
#
def processJSON(json)
  # "Pretty Print" the JSON response
  pp json
end
 
#
# Call the convenience method that POSTs our topic to Primal and then filters
# the default content against the resulting interest network.
#
code, body = primal.postThenFilter("/travel/adventure")
 
# If successful
if code == 200
  # Convert the payload to JSON
  json = JSON.parse(body)
  # Process the result
  processJSON(json)
else
  puts "Something went wrong #{code} -- #{body}"
end
