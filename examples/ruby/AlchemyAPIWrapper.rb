#!/usr/bin/env ruby

# We need to use some ruby gems
require 'rubygems'
require 'uri'

# We require these gems
#
# To install them:
#   gem install httparty
#   gem install json
#
require 'httparty'
require 'json'

#
# The InputTermExtraction class abstracts accessing AlchemyAPI
# (http://www.alchemyapi.com/) to extract important information from Web
# pages/News articles/blog posts/plain text.
#
# The main function is getPrimalRequest, which accepts a string that represents
# a Web page URL or some text, and build a Primal topic URI that will direct the
# user to the Primal Web App.
#
class InputTermExtraction
  include HTTParty

  # Uncomment this next line to see what HTTParty is doing
  # debug_output $stderr

  # Set this to true/false in order to turn on/off debugging of this class
  @@debugMe = true

  @@alchemyRoot = "http://access.alchemyapi.com/calls"
  @@alchemyURL = "#{@@alchemyRoot}/url"
  @@alchemyText = "#{@@alchemyRoot}/text"

  # change these variables to modify how the Primal request is built
  @@entitiesLimit = 1
  @@keywordsLimit = 3

  # We ignore keywords that intersect with entities of the following types:
  @@categoryIgnores = {
    'person'            => 1,
    'organization'      => 1,
    'city'              => 1,
    'company'           => 1,
    'continent'         => 1,
    'country'           => 1,
    'region'            => 1,
    'stateorcountry'    => 1,
    'geographicfeature' => 1
  }

  #
  # Constructor for the InputTermExtraction class
  #
  # Pass in the Api Key for Alchemy services. 
  # You can register for a free API key here:
  #     http://www.alchemyapi.com/api/register.html
  # to test your application. 
  # Please read the license of Alchemy API.
  #
  def initialize(alchemyApiKey)
    @alchemyApiKey = alchemyApiKey
  end

  #
  # Receives a string that represents a Web page URL or some text, and returns 
  # a Primal topic URI.
  #
  # Returns nil on error
  #
  def getPrimalRequest(urlOrText)
    if isURI(urlOrText)
      getPrimalRequestURL(urlOrText)
    else
      getPrimalRequestTEXT(urlOrText)
    end
  end
  
  #
  # Indicates whether or not a given string represents a URL
  #
  def isURI(string)
    uri = URI.parse(string)
    %w( http https ).include?(uri.scheme)
  rescue URI::BadURIError
    false
  rescue URI::InvalidURIError
    false
  end
  
  #
  # Processes the given URL at Alchemy and then translates the results to a
  # valid Primal URL
  #
  def getPrimalRequestURL(urlToProcess)
    if @@debugMe
      $stderr.puts "Extracting information from URL..."
    end

    # get category of the Web page
    categoryJSON = getAlchemy("#{@@alchemyURL}/URLGetCategory",
                              :query => {
                                 :outputMode => 'json',
                                 :apikey => @alchemyApiKey,
                                 :url => urlToProcess
                             })

    # get entities in the Web page
    entitiesJSON = getAlchemy("#{@@alchemyURL}/URLGetRankedNamedEntities",
                              :query => {
                                :outputMode => 'json',
                                :apikey => @alchemyApiKey,
                                :url => urlToProcess
                             })

    # get keywords from the Web page
    keywordsJSON = getAlchemy("#{@@alchemyURL}/URLGetRankedKeywords",
                              :query => {
                                :outputMode => 'json',
                                :apikey => @alchemyApiKey,
                                :url => urlToProcess
                             })

    buildPrimalRequest(categoryJSON, entitiesJSON, keywordsJSON)
  end

  #
  # Processes the given Text at Alchemy and then translates the results to a
  # valid Primal URL
  #
  def getPrimalRequestTEXT(textToProcess)
    if @@debugMe
      $stderr.puts "Extracting information from text..."
    end

    # get category
    categoryJSON = postAlchemy("#{@@alchemyText}/TextGetCategory",
                               :query => {
                                 :outputMode => 'json',
                                 :apikey => @alchemyApiKey,
                                 :text => textToProcess
                              })

    # get entities
    entitiesJSON = postAlchemy("#{@@alchemyText}/TextGetRankedNamedEntities",
                               :query => {
                                 :outputMode => 'json',
                                 :apikey => @alchemyApiKey,
                                 :text => textToProcess
                              })

    # get keywords
    keywordsJSON = postAlchemy("#{@@alchemyText}/TextGetRankedKeywords",
                               :query => {
                                 :outputMode => 'json',
                                 :apikey => @alchemyApiKey,
                                 :text => textToProcess
                              })

    buildPrimalRequest(categoryJSON, entitiesJSON, keywordsJSON)
  end

  #
  # Uses the deconstructed Alchemy information to create a valid Primal URL
  #
  def buildPrimalRequest(categoryJSON, entitiesJSON, keywordsJSON)
    # Check if any of the extractions failed
    if !categoryJSON or !entitiesJSON or !keywordsJSON
       $stderr.puts "Cannot build Primal request. Alchemy failed to extract information."
       return nil
    end
    
    if @@debugMe
      $stderr.puts "Building Primal request..."
    end
   
    ### Get information required for building a Primal request
    # Get the category from the extracted data
    category = rewriteCategory(categoryJSON['category'])

    if @@debugMe
      $stderr.puts "Category = #{category}"
    end
        
    ### Select top entities from all extracted entities
    entitiesList = entitiesJSON['entities'].collect { |entity|
      entity['text'].downcase
    }[0, @@entitiesLimit]
    
    if @@debugMe
      prettified = entitiesJSON['entities'].collect { |entity|
        entity['text']
      }.join(', ')
      $stderr.puts "Entities = #{prettified}"
    end
    
    ### Select top keywords from all extracted keywords
    # Remove keywords that intersect with entities of the types in @@categoryIgnores
    allEntities = entitiesJSON['entities'].select { |entity|
      @@categoryIgnores.has_key? entity['type'].downcase
    }.collect { |entity|
      entity['text'].downcase
    } 
    
    if @@debugMe
      prettified = keywordsJSON['keywords'].collect { |keyword|
        keyword['text']
      }.join(', ')
      $stderr.puts "Keywords = #{prettified}"
    end
    
    keywordsList = keywordsJSON['keywords'].select { |keyword|
      normalizedKw = keyword['text'].downcase
      intersectsWithEntity = !(allEntities.select { |entity|
                                   entity.include? normalizedKw or normalizedKw.include? entity
                                 }.empty?)
      # Ignore keywords > 4 words or those that intersect with entities
      normalizedKw.split.size < 5 && !intersectsWithEntity
    }.collect { |keyword|
      keyword['text'].downcase
    }
      
    # Remove repeated keywords
    keywordsList = getNonRepeatedKeywords(keywordsList)
    
    ### Build Primal topic URI
    primalRequest = ""
    unless category.nil?     then primalRequest = "/" + category end
    if entitiesList.size > 0 then primalRequest = primalRequest + "/" + entitiesList.join("/") end
    if keywordsList.size > 0 then primalRequest = primalRequest + "/" + keywordsList.join(";") end
    if @@debugMe
      $stderr.puts "Primal request = #{primalRequest}"
    end
    URI::encode(primalRequest)
  end #function

  #
  # Returns the top @@keywordsLimit keywords, ignoring those contained 
  # within other keywords   
  #
  def getNonRepeatedKeywords(keywordsList)
    # If there is less than @@keywordsLimit, or if the first @@keywordsLimit keywords
    # are unique, return the first @@keywordsLimit keywords
    repeatedKeywords = getRepeatedKeywords(keywordsList[0, @@keywordsLimit])
    if keywordsList.length <= @@keywordsLimit or repeatedKeywords.empty?
      keywordsList[0, @@keywordsLimit] 
    else
      # Remove repeated elements from the first @@keywordsLimit keywords, and recursively
      # call this function
      getNonRepeatedKeywords(keywordsList - repeatedKeywords)
    end
  end
  
  #
  # Returns any repeated words in the list
  #
  def getRepeatedKeywords(keywordsList)
    keywordsList.select { |keyword|
           not(keywordsList.select { |other|
             other != keyword and other.include? keyword
           }.empty?)
    }
  end
  
  #
  # Modifies the extracted category string to become a clear topic in the Primal
  # request.
  #
  # AlchemyAPI categorizes text into a limited set of category types.
  #
  #    See http://www.alchemyapi.com/api/categ/categs.html for a complete list.
  #
  # Some of the cateogy type names have two strings concatenated by an
  # underscore character. This function selects one of the two strings (or a
  # totally new string) to be the topic in the Primal request.
  #
  def rewriteCategory(category)
    case category
    when "unknown"               # AlchemyAPI failed to classify the text
      category = nil
    when "arts_entertainment"    
      category = "arts"          # rewrite to 'arts'
    when "computer_internet"
      category = "technology"    # rewrite to 'technology', a clearer topic for this category
    when "culture_politics"
      category = "politics"      # rewrite to 'politics'
    when "law_crime"
      category = "law"           # rewrite to 'law'
    when "science_technology"
      category = "science"       # rewrite to 'science'
    else
      # The previous conditions should cover all the categories extracted by
      # Alchemy.  In case of a new category that contains an underscore, replace
      # it and keep the two words as the topic. 
      category = category.sub('_', ' ')
    end
  end

  #
  # Perform a POST request to Alchemy service URL and return the response as a
  # JSON object
  #
  # Returns nil on error
  #
  def postAlchemy(serviceURL, parameters)
    response = self.class.post(serviceURL, parameters)
    returnAlchemyResponseJSON(response)
  end
  
  #
  # Perform a GET request to Alchemy service URL and return the 
  # response as a JSON object
  #
  # Returns nil on error
  #
  def getAlchemy(serviceURL, parameters)
    response = self.class.get(serviceURL, parameters)
    returnAlchemyResponseJSON(response)
  end

  #
  # Return the body of the response in a JSON object 
  # or nil on error
  #
  def returnAlchemyResponseJSON(response)
    code = response.code
    body = response.body
    bodyJSON = JSON.parse(body)

    # A statusInfo field contains the details of the error 
    if bodyJSON['status'] != "OK"
      puts bodyJSON['statusInfo']
      nil
    else
      bodyJSON
    end
  end
end
