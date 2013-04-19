#!/usr/bin/env ruby

# We need to use some ruby gems
require 'rubygems'

# We require these gems
#
# To install them:
#   gem install httparty
#   gem install json
#
require 'httparty'
require 'json'

#
# The PrimalAccess class abstracts the access to Primal such
# that you can call simple methods on it to get what you need.
#
class PrimalAccess
  include HTTParty
  base_uri 'https://data.primal.com'
  # Uncomment this next line to see what HTTParty is doing
  # debug_output $stderr
  # Set this to false in order to turn off debugging of this class
  @@debugMe = true

  #
  # Constructor for the PrimalAccess class
  #
  # Pass in the username and password of the user you're going
  # to access in order to construct and object that will work
  # with that user
  #
  def initialize(appId, appKey, username, password)
    @headers = {
      :headers => {
        'Primal-App-ID' => appId,
        'Primal-App-Key' => appKey
      },
      :basic_auth => {
        :username => username,
        :password => password
      }
    }
  end

  #
  # Sometimes we're going to get topics that are complex (i.e. they contain a
  # scheme and host) and we want to simplify those.  Because we're not making
  # calls with bare URLs but have told HTTParty what the base_uri is, we need to
  # pull that base uri off of the topic, should it be there.
  #
  def extractJustTopic(topic)
    topic.sub(%r{https://.*?/}, '/')
  end

  #
  # POSTs a new topic to Primal in order to seed that topic.
  #
  # The 'topic' parameter will be used to construct a POST URL
  # that looks like "/topic"
  #
  # Returns two values: the response code and the body.
  # Anything but a response code of 201 is to be considered
  # an error.
  #
  def postNewTopic(topic, opts = {})
    topic = extractJustTopic(topic)
    count = 0
    code = 400
    body = ''
    options = @headers.merge(opts)
    while (count < 5)
      if @@debugMe
        $stderr.puts "POSTing to #{topic}"
      end
      response = self.class.post("#{topic}", options)
      code = response.code
      body = response.body
      #
      # 400 - bad request
      # 401 - application not authorized to access the user's account
      # 403 - application not authorized to use Primal
      #
      if code >= 400 && code <= 403
        if @@debugMe
          $stderr.puts "POST received a #{code}"
        end
        break
      #
      # 429 - application has reached its request limit for the moment
      #
      elsif code == 429
        # Sleep for 10 seconds
        if @@debugMe
          $stderr.puts "Got a 429.  Waiting (#{count})."
        end
        sleep 10
        count += 1
      #
      # 201 - success
      #
      elsif code == 201
        if @@debugMe
          $stderr.puts "POST successful"
        end
        break
      else
        abort "Received unexpected response code (#{code}) for POST #{uri}"
      end
    end
    return code, body
  end

  #
  # Uses the pre-existing topic to filter the default source
  # of content through the interest network defined by the topic.
  #
  # The given parameter will be used to construct a GET URL
  # that looks like "/topic"
  #
  # You can pass a dictionary of optional arguments that will
  # be merged in to the query parameters, if you wish.
  # e.g. 
  #   { :"primal:contentScore:min" => 0.7 }
  #   { :"primal:contentCount:max" => 5 }
  #   { :contentSource => MyDataSource } ... or ...
  #   { :contentSource => PrimalSource }
  #
  # Returns two values: the response code, and the body.
  # If successful (i.e. a response code of 200) then the body
  # will be the JSON payload of the filtered content.
  #
  def filterContent(topic, opts = {})
    topic = extractJustTopic(topic)
    count = 0
    code = 400
    body = ''
    options = @headers.merge({ :query => {
        :timeOut => 'max'
      }.merge(opts)
    })
    while (count < 10)
      if @@debugMe
        $stderr.puts "GETting #{topic}"
      end
      response = self.class.get("#{topic}", options)
      code = response.code
      body = response.body
      #
      # 400 - bad request
      # 401 - application not authorized to access the user's account
      # 403 - application not authorized to use Primal
      # 404 - object not found
      #
      if code >= 400 && code <= 404
        if @@debugMe
          $stderr.puts "GET received a #{code}"
        end
        break
      #
      # 429 - application has reached its request limit for the moment
      #
      elsif code == 429
        if @@debugMe
          $stderr.puts "Got a 429.  Waiting (#{count})."
        end
        # Sleep for 10 seconds
        sleep 10
        # We don't allow as many retries when we might be throttled
        count += 2
      #
      # 200 - success
      #
      elsif code == 200
        if @@debugMe
          $stderr.puts "Results are complete"
        end
        break
      #
      # We don't know what happened but it can't be good
      #
      else
        abort "Received unexpected response code (#{code}) for GET #{topic}"
      end
    end
    return code, body
  end

  #
  # This is a convenience method that will POST the topic to
  # Primal and then filter the default source of content through the
  # resulting interest network.
  #
  # The response from this method is a bit less clear than using
  # a POST and filter explicitly, since you may not know which
  # one of the two operations has failed (assuming a failure).
  #
  # Returns two values: the response code and the body.  The only
  # successful response code from this method is 200.  If
  # successful then the body contains the JSON payload of the
  # filtered content.
  #
  def postThenFilter(topic, opts = {})
    code, body = postNewTopic(topic)
    if code == 201
      code, body = filterContent(topic, opts)
    end
    return code, body
  end
end
