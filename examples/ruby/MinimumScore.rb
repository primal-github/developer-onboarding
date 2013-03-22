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
# By adding 'primal:contentScore:min=0.7' in the query parameter of the URL, we direct the data
# service to return content to us that scores 0.7 or better.  The resulting URL
# will look something like this:
#
#    https://data.primal.com/travel/adventure?primal:contentScore:min=0.7
#
code, body = primal.filterContent("/travel/adventure", {
                                    :"primal:contentScore:min" => 0.7
                                  })
 
#
# We use the processJSON() function as we have in other examples to process the
# results from the GET.  This just extracts what we need and displays it without
# all of the extra noise from the JSON response.
#
def processJSON(json)
  # Let's just print out titles, links and scores
  json['dc:collection'].collect { |dict|
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
