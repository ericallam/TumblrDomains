class RegistrationsController < ApplicationController

  def new
    @registration = Registration.new(:domain => params[:domain_name])
  end

  def create
    @registration = Registration.new(params[:registration])

    respond_to do |format|
      if @registration.save
        
        self.current_registration = @registration

        format.html {
          redirect_to choose_tumblelog_registration_path(@registration)
        }
        
        format.js {
          render :json => { :success => true, :tumblelogs => @registration.tumblelogs }
        }
      else
        format.html {
          render :action => :new
        }
        format.js {
          render :json => { :success => false, :errors => @registration.errors }
        }
      end
    end
  end

  def set_tumblelog
    @registration = current_registration

    respond_to do |format|
      if @registration.update_attributes(params[:registration])
        format.js {
          render :json => {:success => true, :payment_url => payment_url(@registration) }
        }
      else
        format.js {
          render :json => {:success => false, :errors => @registration.errors}
        }
      end
    end
  end

  def choose_tumblelog
    @registration = Registration.find(params[:id])
  end

  private

  def payment_url(registration)
    AmazonFPS.cobrand_url(registration.amount, "Recurring", registration.reference, registration.reason, payment_callback_url)
  end
end
