class PaymentsController < ApplicationController
  

  def create

    fps_response = AmazonFPS::CobrandResponse.new(params)

    if fps_response.success?

      payment = AmazonFPS::Pay.new(fps_response.caller_reference, fps_response.token, BigDecimal.new("9.95")).call

      if payment.success?
        registration = current_registration
        
        registration.update_attribute :transaction_id, payment.transaction_id

        registration.modify_tumblelogs_domain!

        handler = registration.register!

        if handler.success?
          redirect_to payment_complete_path
        else
          # background job, retry to register
          redirect_to registration_problem_path, :error => handler.error_message
        end
      else
        # payment.error_message
        redirect_to payment_problem_path, :error => payment.error_message
      end
    else
      redirect_to payment_problem_path, :error => fps_response.error_message
    end

  end

  def thank_you
    @registration = current_registration
  end

  def problem
    @registration = current_registration
  end

  def registration_problem
    @registration = current_registration
  end
end
