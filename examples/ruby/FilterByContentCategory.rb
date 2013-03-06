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
# Here's the important bit.  We're going to parse the JSON response
# and accept only those entries in the dc:collection whose dc:type
# value is "Web"
#
def processJSON(json)
  collection = json['dc:collection']
  # Select only those entries for which the dc:type is "Web" and
  # then transform them into strings that look pretty
  results = collection.select { |dict|
    dict['dc:type'] == "Web"
  }.collect { |dict|
    "title: #{dict['dc:title']}\n" +
    "link: #{dict['dc:identifier']}\n" +
    "source: #{dict['dc:type']}\n\n"
  }.each { |result|
    puts result
  }
end
 
#
# Call the convenience method that POSTs our topic to Primal and
# then filters the content against the resulting interest network.
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
