class DomainsController < ApplicationController

  def check_availability
    @answer = whois.query(params[:domain_name])

    respond_to do |format|
      format.js {
        if @answer.available?
          render :json => {:available => true }
        else
          render :json => {:available => false, :error => "Sorry, but #{params[:domain_name]} is not available to register." }
        end
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

  before_filter :check_empty
  before_filter :check_top_level_domain

  private

  def check_empty
    if params[:domain_name].blank?
      render :json => {:available => false, :error => 'Sorry, but you entered a blank domain name.'} and return false
    end
  end

  def check_top_level_domain
    top_level_domain = params[:domain_name].split('.').last
    unless Registrar.allowable_top_level_domains.include?(top_level_domain)
      render :json => {:available => false, :error => 'Sorry, but we only support .com and .net domain names'} and return false
    end
  end

end
