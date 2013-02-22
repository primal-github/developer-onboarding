#!/usr/bin/env ruby

# We need to use some ruby gems
require 'rubygems'

# We require the httparty gem
#
# To install it:
#   gem install httparty
#
require 'httparty'

#
# The PrimalAccess class abstracts the access to Primal such
# that you can call simple methods on it to get what you need.
#
class PrimalAccess
  include HTTParty
  base_uri 'https://data.primal.com'
  # Uncomment this next line to see what HTTParty is doing
  # debug_output $stderr
  headers 'Primal-Version' => 'latest'

  #
  # Constructor for the PrimalAccess class
  #
  # Pass in the username and password of the user you're going
  # to access in order to construct and object that will work
  # with that user
  #
  def initialize(appId, appKey, username, password)
    headers 'Primal-App-ID' => appId
    headers 'Primal-App-Key' => appKey
    @headers = {
      :basic_auth => {
        :username => username,
        :password => password
      }
    }
  end

  #
  # POSTs a new topic to Primal in order to seed that topic.
  #
  # The 'storage' and 'topic' parameters will be used to
  # construct a POST URL that looks like
  # "/storage@Everything/topic"
  #
  # Returns two values: the response code and the body.
  # Anything but a response code of 201 is to be considered
  # an error.
  #
  def postNewTopic(storage, topic)
    response = self.class.post("/#{storage}@Everything#{topic}",
                               @headers)
    return response.code, response.body
  end

  #
  # Uses the pre-existing topic to filter the source of content
  # through the interest network located in storage.
  #
  # The given parameters will be used to construct a GET URL
  # that looks like "/storage@source/topic"
  #
  # You can pass a dictionary of optional arguments that will
  # be merged in to the query parameters, if you wish.
  # e.g. { :minScore => 0.7 }
  #
  # Returns two values: the response code, and the body.
  # If successful (i.e. a response code of 200) then the body
  # will be the JSON payload of the filtered content.
  #
  def filterContent(storage, source, topic, opts = {})
    count = 0
    code = 400
    body = ''
    options = @headers.merge({ :query => {
      :status => 'complete',
      :timeOut => 300 }.merge(opts)
    })
    while (count < 5)
      response = self.class.get("/#{storage}#{source}#{topic}",
                                options)
      code = response.code
      body = response.body
      if response.code == 404
        break
      elsif response.code != 200
        count += 1
      else
        break
      end
    end
    return code, body
  end

  #
  # This is a convenience method that will POST the topic to
  # Primal and then filter the source of content through the
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
  def postThenFilter(storage, source, topic)
    code, body = postNewTopic(storage, topic)
    if code == 201
      code, body = filterContent(storage, source, topic)
    end
    return code, body
  end
end
