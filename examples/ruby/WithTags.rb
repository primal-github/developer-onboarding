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
code, body = primal.postThenFilter("/travel/adventure")
 
# 
# Returns an unordered list of the matched topics and their URL
# identifiers back in to Primal.
# 
# dcCollectionEntry - The JSON object pulled from the dc:collection.
#   topicsJson - The JSON object represented by
#   skos:ConceptScheme/skos:Collection.
# Returns the unordered list of matched topics or the empty string
#   if no topics can be found.
# 
def getSubjectTags(dcCollectionEntry, topicsJson)
  # Get the subjects from the dcCollectionEntry
  subjects = dcCollectionEntry['dc:subject']
 
  # If they're defined
  if subjects
    # Convert the subject links to subject labels
    strings = subjects.collect { |subj|
      # Look up the object in the skos block and extract the label
      topicsJson[subj]['skos:prefLabel']
    }
    # Make it look nice
    strings.join(", ")
  else
    ""
  end
end
 
#
# Again, this is where to find the bulk of our changes.  We need to
# grab the dc:collection block as well as the skos:Collection block
# from the skos:ConceptScheme.  These give us enough data to extract
# the needed bits and pieces of each entry in the dc:collection.
#
def processJSON(json)
  # Extract the dc:collection array
  dcCollection = json['dc:collection']
 
  # Extract the skos:Collection dictionary
  skosCollection = json['skos:ConceptScheme']['skos:Collection']
 
  data = dcCollection.collect { |dict|
    # Extract our needed information from the dictionary
    score = dict['primal:contentScore']
    title = dict['dc:title']
    link = dict['dc:identifier']
 
    # Generated a list of tag names that matched the content
    tagNames = getSubjectTags(dict, skosCollection)
 
    # Grab the identifier links as well so that we can ask the
    # data service for more information about these subjects
    tagLinks = dict['dc:subject'].collect { |link|
      "        #{link}"
    }.join("\n")
 
    # Create the string to be returned to 'data'
    "#{title}\n" +
    "    Relevancy score: #{score}\n" +
    "    Link to source: #{link}\n" +
    "    Matched topics: #{tagNames}\n" +
    "    Matched topic links:\n#{tagLinks}\n\n"
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
