module DomainChanger
  mattr_accessor :handler

  class TumblrChanger
    def initialize(blog_name, email, password)
      @blog_name = blog_name
      @email = email
      @password = password
    end

    def change_to(domain_name)
      agent = Mechanize.new

      login_page = agent.get('http://www.tumblr.com/login')
      login_form = login_page.form_with(:action => "/login")
      login_form.email = @email
      login_form.password = @password

      agent.submit(login_form)

      customize_page = agent.get("http://www.tumblr.com/customize/#{@blog_name}")
      customize_form = customize_page.form_with(:action => "http://www.tumblr.com/customize/#{@blog_name}")
      customize_form.checkbox_with(:name => 'enable_cname').check
      customize_form.cname = domain_name

      agent.submit(customize_form)
    end

  end

  class MockChanger < TumblrChanger
    def change_to(*args)
      true
    end
  end

  def self.handler
    @handler ||= TumblrChanger
  end
end
