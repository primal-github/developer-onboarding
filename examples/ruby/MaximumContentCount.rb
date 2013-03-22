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
# We're going to use the special last parameter in the filterContent call that
# allows us to specify parameters that will go into the query of the GET call.
# By adding 'primal:contentCount:max=20' in the query parameter of the URL, we direct
# the data service to return no more than 20 items to us
#
#   https://data.primal.com/travel/adventure?primal:contentCount:max=20
#
code, body = primal.filterContent("/travel/adventure", {
                                    :"primal:contentCount:max" => 20
                                  })
 
#
# We've made this a separate function because it's going to be
# what we're going to be modifying most often.  The data service
# will return to us, a JSON payload as a regular order of 
# business.  What's going to change is how we manipulate that
# result.  For now, we're starting small
#
def processJSON(json)
  count = 0
  # Let's just print out titles, links, scores and index number
  json['dc:collection'].collect { |dict|
    count += 1
    "index: #{count}\n" +
    "title: #{dict['dc:title']}\n" +
    "link: #{dict['dc:relation']}\n" +
    "score: #{dict['primal:contentScore']}\n\n"
  }.each { |result|
    puts result
  }
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
