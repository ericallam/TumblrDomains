class DomainsController < ApplicationController

  def check_availability
    @answer = whois.query(params[:domain_name])

    respond_to do |format|
      format.js {
        render :json => {:available => @answer.available?, :answer => @answer.properties}
      }
      format.html {
        if @answer.available?
          redirect_to new_registration_path(:domain_name => params[:domain_name])
        else
          redirect_to "/", :error => "Sorry, that domain is not available."
        end
      }
    end
  end

end
