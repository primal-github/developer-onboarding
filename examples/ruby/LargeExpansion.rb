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
# We're not going to do anything special here.  You know how to
# manipulate the results to get some bits and pieces of information that
# are important to you, so let's just fly past this right now.
#
def processJSON(json)
  # "Pretty Print" the JSON response
  pp json
end
 
#
# Here we're going to be creating a large graph of interests that descend
# from 'travel'.  The graph of interests that Primal is going to create
# will be extreme indeed!
#
interests = [
    '/travel/canada/north/adventure/skiing;hiking;climbing;sledding',
    '/travel/norway/kayak;iceberg;paddle',
    '/travel/adventure/alaska/hunting;camping;survival',
    '/travel/adventure/arctic/igloo;ice+fishing;survival;snow+mobile',
    '/travel/extreme/winter/mountain+climbing;death'
]

# 
# Now we're going to use the head topic of our interest network for
# filtering purposes.  The graph Primal has created is going to used
# to forumlate the terms we use for filtering.
#
interestForFiltering = "/travel"
 
#
# Expand around all of our topics, each in turn
#
interests.each { |topic|
    puts "Expanding #{topic}..."
    code, body = primal.postNewTopic("traveldemo", topic)
    if code != 201
        abort "Unable to expand topics around #{topic}.\n" +
              "Error #{code}, message: \"#{body}\""
    end
}

#
# Now that the interests have been expanded, lets use them to grab
# some content that intersects with them
#
puts "Filtering content..."
code, body = primal.filterContent("traveldemo", "@Everything",
                                  interestForFiltering)

# If successful
if code == 200
  # Convert the payload to JSON
  json = JSON.parse(body)
  # Process the result
  processJSON(json)
else
  puts "Something went wrong #{code} -- #{body}"
end
