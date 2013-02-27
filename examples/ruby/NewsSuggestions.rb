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
 
# Constructs the PrimalAccess object so we can talk to Primal
$primal = PrimalAccess.new("<your appId>", "<your appKey>",
                          "<your username>", "<your password>")
 
#
# Our ficticious user is interested in the following areas of technology
#
$interests = [
    '/technology/Twitter',
    '/technology/Nokia;mobile',
    '/technology/Facebook;virus',
    '/technology/Google;laptop'
]

# 
# Now we're going to use the head topic of our interest network for
# filtering purposes.  The graph Primal has created is going to used to
# forumlate the terms we use for filtering.
#
$interestForFiltering = "/technology"
 
#
# We're not going to do anything special here.  You know how to manipulate
# the results to get some bits and pieces of information that are important
# to you, so let's just fly past this right now.
#
def processJSON(source, json)
  # Grab the array from dc:collection
  collection = json['dc:collection']
  # Convert that array to an array of strings
  data = collection.collect { |dict|
    "  score: #{dict['primal:contentScore']}\n" +
    "  title: #{dict['dc:title']}\n" +
    "  link: #{dict['dc:identifier']}\n\n"
  }
  puts "From #{source}:"
  puts data
  # Return the top scoring item's first subject
  if collection.first['dc:subject']
      collection.first['dc:subject'].first
  else
      ""
  end
end
 
#
# This function will make it easier to pull content for our new interest
# network from different sources.
#
def filterBySource(source)
  puts "Filtering content from #{source}..."
  code, body = $primal.filterContent("techdemo", source,
                                     $interestForFiltering)
  # If successful
  if code == 200
      # Convert the payload to JSON
      json = JSON.parse(body)
      # Process the result
      processJSON(source, json)
  else
      puts "Something went wrong #{code} -- #{body}"
  end
end

#
# Expand around all of our topics, each in turn
#
$interests.each { |topic|
    puts "Expanding #{topic}..."
    code, body = $primal.postNewTopic("techdemo", topic)
    if code != 201
        abort "Unable to expand topics around #{topic}.\n" +
              "Error #{code}, message: \"#{body}\""
    end
}

#
# Now that the interests have been expanded, lets use them to grab some
# content that intersects with them, but lets do it for a number of
# different content sources.  This way, we can pass a different "lens"
# across our interests, which will give us some deeper insight into the
# content that intersects with them.
#
filterBySource("@News")    # ignore the returned subject for this
filterBySource("@Videos")  # ignore the returned subject for this
filterBySource("@Social")  # ignore the returned subject for this
filterBySource("@Images")  # ignore the returned subject for this

# Now we'll use the top scoring item's first subject, and further drill
# down on that subject to get more information
subject = filterBySource("@News+mobile")

# Regex needed to rip out https://data.primal.com/{storage}@{source}/
subject = subject.gsub(%r{^https://.*?/.*?/}, '/')

puts "Grabbing content for #{subject}..."
# Let's go a bit deeper and pull some @News about this particular subject
code, body = $primal.postThenFilter("techdemo", "@News", subject)
# If successful
if code == 200
    # Convert the payload to JSON
    json = JSON.parse(body)
    # Process the result
    processJSON("@News", json)
else
    puts "Something went wrong #{code} -- #{body}"
end
