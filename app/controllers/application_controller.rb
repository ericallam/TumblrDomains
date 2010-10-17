class ApplicationController < ActionController::Base
  protect_from_forgery

  private

  def whois
    @whois ||= Whois::Client.new
  end

  def current_registration
    @current_registration ||= Registration.find_by_id(session[:registration_id])
  end

  def current_registration=(r)
    session[:registration_id] = r.id
    r
  end
end
