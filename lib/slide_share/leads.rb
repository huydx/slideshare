module SlideShare
  class Leads
    attr_accessor :base

    # This method should only be called internally from an instance of
    # <tt>SlideShare::Base</tt>.
    def initialize(base) # :nodoc:
      self.base = base
    end

    def find_campaigns_by_user(username, password)
      user_info = {:username => username, :password => password}
      base.send :get, "/get_user_leads", user_info
    end
  end
end
