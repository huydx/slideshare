require "digest/sha1"

module SlideShare
  class Base
    include HTTParty
    @@base_uri    = "https://www.slideshare.net/api/2"
    @@oembed_uri  = "http://www.slideshare.net/api/oembed/2"

    format :xml

    attr_accessor :api_key, :shared_secret

    # Returns an instance of <tt>SlideShare::Base</tt>. Takes the following options:
    #
    # * <tt>:api_key</tt> - SlideShare API key
    # * <tt>:shared_pass</tt> - SlideShared shared secret
    #
    # Alternatively, this method may take the path to a YAML file containing
    # this data. Examples (of both):
    #
    #   # Using the options hash
    #   @slideshare = SlideShare::Base.new(:api_key => "4815162342", :shared_secret => "dharma")
    #   # Using the YAML file
    #   @slideshare = SlideShare::Base.new("path/to/file.yml")
    def initialize(hash_or_yaml)
      config = hash_or_yaml.is_a?(Hash) ? hash_or_yaml :
        YAML.load_file(hash_or_yaml)
      self.api_key = config[:api_key]
      self.shared_secret = config[:shared_secret]
      unless api_key && shared_secret
        raise ArgumentError, "Configuration must have values for :api_key and :shared_secret"
      end
    end

    # OO abstraction for <tt>SlideShare::Slideshow</tt> namespace. Example usage:
    #
    #   @slideshare = SlideShare::Base.new("path/to/file.yml")
    #   @slideshow = @slideshare.slideshows.find(815)
    #
    # This is recommended over initializing and accessing a <tt>SlideShare::Slideshow</tt>
    # object directly.
    def slideshows
      @slideshow ||= Slideshows.new(self)
    end

    def leads
      @lead ||= Leads.new(self)
    end

  private
    def get(*args)
      self.class.base_uri @@base_uri
      puts (query = add_required_params(args.extract_options!)).inspect
      catch_errors self.class.get(args.first,
        {:query => query})
    end

    #obemded api
    #parameters:
    # url: url of slide to get oembeded info
    # optional parameters:
    # - maxwidth (optional) : The maximum width of the embed in pixels.
    # - maxheight (optional) : The maximum height of the embed in pixels.
    # - format (optional) : xml, json, jsonp
    # - callback (optional) : Returns jsonp response format. callback is name of the JavaScript
    def get_obembed(url, optional_args = {})
      self.class.base_uri @@oembed_uri
      args = optional_args.merge(:url => url)
      catch_errors self.class.get('', query: args, 'charset'=>'utf-8')
    end

    def post(*args)
      options = add_required_params(args.extract_options!)
      catch_errors self.class.post(args.first,
        {:query => options})
    end

    def add_required_params(options)
      now = Time.now.to_i.to_s
      hashed = Digest::SHA1.hexdigest("#{shared_secret}#{now}")
      options.merge(:api_key => api_key, :ts => now, :hash => hashed)
    end

    def catch_errors(response)
      if error = response.delete("SlideShareServiceError")
        case error["Message"]
        when /failed user authentication/i
          raise FailedUserAuthentication
        when /insufficient permission/i
          raise InsufficientPermission
        when /slideshow not found/i
          raise SlideshowNotFound
        else
          raise ServiceError, error["Message"]
        end
      else
        response
      end
    end
  end
end
