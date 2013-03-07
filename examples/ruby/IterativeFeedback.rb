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
 
# We'll hard-code these specific sources to make things simpler
$sources = [ "@News", "@Videos", "@Web", "@Everything" ]

# 
# Returns an unordered list of the matched topics and their URL identifiers back
# in to Primal.
# 
# dcCollectionEntry - The JSON object pulled from the dc:collection.
# skosCollection - The JSON object represented by
#   skos:ConceptScheme/skos:Collection.
# Returns a list dictionaries with :subject and :prefLabel as entries.
# 
def getSubjectTags(dcCollectionEntry, skosCollection)
  # Get the subjects from the dcCollectionEntry
  subjects = dcCollectionEntry['dc:subject']
 
  # If they're defined
  if subjects
    # Convert the subject links to subject labels
    strings = subjects.collect { |subj|
      # Look up the object in the skos block and extract the label
      {
        :subject => subj,
        :prefLabel => skosCollection[subj]['skos:prefLabel']
      }
    }
  else
    []
  end
end
 
#
# We're looking to process the JSON response into a new data structure that can
# be used to present information to the user.
#
def processJSON(json)
  # Grab the array from dc:collection
  dcCollection = json['dc:collection']
  # Grab the skos block
  skosCollection = json['skos:ConceptScheme']['skos:Collection']
  # Convert the JSON into an array of dictionaries that we can present to
  # the user
  dcCollection.collect { |dict|
    {
      :score => dict['primal:contentScore'],
      :title => dict['dc:title'],
      :link => dict['dc:identifier'],
      :subjects => getSubjectTags(dict, skosCollection)
    }
  }.reverse # orders it by reverse score so that the best stuff is at the
            # bottom. It'll look better for the user so that they don't have to
            # scroll up
end
 
#
# We first create an interest network around a given topic and then filter the
# the given source of content through that resulting network in this one
# function.  The returned data is exactly what was returned from processJSON()
#
def postAndFilter(topic, source)
  print "Creating interests around #{topic}..."
  STDOUT.flush
  code, body = $primal.postNewTopic("iterativedemo", topic)
  # If successful
  if code == 201
    puts " success."
    print "Filtering #{topic} against #{source}..."
    STDOUT.flush
    code, body = $primal.filterContent("iterativedemo", source, topic)
    if code == 200
      puts " success."
      # Convert the payload to JSON
      json = JSON.parse(body)
      # Process the result
      processJSON(json)
    else
      abort "Filtering request failed (#{code}). Message: #{body}"
    end
  else
    abort "Creation request failed (#{code}). Message: #{body}"
  end
end

#
# Display the subjects within an entry of the dc:collection block to the user
#
def printSubjects(subjects)
  subjects.each_index { |j|
    puts "    #{j}) #{subjects[j][:prefLabel]}"
  }
end

#
# Displays the JSON results to the user in a way that they can then select from
# them later
#
def printResults(data)
  puts "\n\n"
  puts "======================================="
  puts "\n"
  data.each_index { |i|
    puts "#{i})"
    puts "  score: #{data[i][:score]}"
    puts "  title: #{data[i][:title]}"
    puts "  link:  #{data[i][:link]}"
    puts "  subjects:"
    printSubjects(data[i][:subjects])
  }
end

#
# Asks the user to enter a number, checks to ensure that they've done so
# properly and returns that result to the caller
#
def getUserIndex(message, max)
  while true
    puts "\n#{message} ('q' quits)"
    idx = gets().chomp()
    if idx =~ %r{[qQ]}
      puts "See ya!"
      exit(0)
    elsif idx =~ %r{\s*\d+\s*} && idx.to_i >= 0 && idx.to_i < max
      return idx.to_i
    else
      puts "\nI don't know what '#{idx}' is, but it's not a valid index\n\n"
    end
  end
end

#
# Returns one of the entries from the $sources array depending on the user's
# specification
#
def getSourceFromUser()
  puts
  $sources.each_index { |i|
    puts "#{i}) #{$sources[i]}"
  }
  $sources[getUserIndex("Which source do you want to use?", $sources.length)]
end

# ====================
# Main
# ====================

# Start the ball rolling with an initial set of topics
puts "Give me a topic (in Primal hierarchical form - e.g. /adventure/hiking;france):"
topic = gets().chomp()

# Get a starting source
source = getSourceFromUser()

# Start the loop
while true
  puts "Alright, let's do it..."

  # Get the filtered content from Primal
  data = postAndFilter(topic, source)

  # Show it to the user
  printResults(data)

  # Ask them which piece of content to look at
  idx = getUserIndex("Which content number do you want to look into?", data.length)

  # Get the subject to feed back into primal
  subjects = data[idx][:subjects]
  printSubjects(subjects)
  idx = getUserIndex("Which subject do you want to look into?", subjects.length)

  # Get the topic and the source and get ready to do it again!
  topic = subjects[idx][:subject].gsub(%r{^https://.*?/.*?/}, '/')
  source = getSourceFromUser()
end
