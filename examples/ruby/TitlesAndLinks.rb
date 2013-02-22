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
# Call the convenience method that POSTs our topic to Primal and
# then filters the content against the resulting interest network.
#
code, body = primal.postThenFilter("traveldemo", "@Everything",
                                   "/travel/adventure")
 
#
# Our changes are here.  All we need to do is grab the dc:collection
# block from the JSON response and transform it to a collection of
# strings that contain the information we care about.
#
def processJSON(json)
  # Grab the array from dc:collection
  collection = json['dc:collection']
  # Convert that array to an array of strings
  data = collection.collect { |dict|
    "title: #{dict['dc:title']}\nlink: #{dict['dc:identifier']}\n\n"
  }
  puts data
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
