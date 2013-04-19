#!/usr/bin/env ruby

# Load in the PrimalAccess class
require './PrimalAccess.rb'
require 'rubygems'
require 'pp'

# We require the json gem.
#
# To install it:
#   gem install json
#
require 'json'

# Constructs the PrimalAccess object so we can talk to Primal
$primal = PrimalAccess.new("<your appId>", "<your appKey>",
                           "<your username>", "<your password>")

# To bootstrap the example, we're going to use this array to hold the list of
# interests that would normally come from some outside source; e.g. user input,
# information extracted from a website or document abstract, etc...
$interests = [
    '/technology/Twitter',
    '/technology/Nokia;mobile',
    '/technology/Facebook;virus',
    '/technology/Google;laptop'
]

# Now we create interests using the POST command on each topic in turn
# In order to keep our concerns separated, we're going to model a "user" with a
# specifici storage location for the interest network in Primal.
$interests.each { |interest|
  $primal.postNewTopic(interest, {
    :storage => "user1234"
  })
}

# News content can now be filtered through our interest network
# (assumes the default content source is News)
code, body = $primal.filterContent("/technology", {
                                    :contentSource => "PrimalSources/News",
                                    :storage => "user1234"
                                  })
response = JSON.parse(body)

# Just print out the titles for fun
puts "Got News results for technology from Primal:"
response['dc:collection'].each { |dict| puts dict['dc:title'] }

# Grab the subjects from the first piece of content we get back (which will be
# the highest scoring one) and post that back to Primal.  For example, the array
# of subjects from the first piece of content might look like:
#
#  "dc:subject": [
#    "https://data.primal.com/technology/mobile+broadband",
#    "https://data.primal.com/technology/mobile+telephony",
#    "https://data.primal.com/technology/internet",
#    "https://data.primal.com/technology/communications",
#    "https://data.primal.com/technology"
#  ]
#
# One could easily envision a user selecting a piece of content from which you
# would grab subjects, or they could grab a specific subject, etc...
#
# We're just going to POST them all back in.
#
response['dc:collection'][0]['dc:subject'].each { |subject|
  $primal.postNewTopic(subject, {
    :storage => "user1234"
  })
}

# And so on...
