class PushSubscriptionsController < ApplicationController
  include Authentication

  def create
    subscription_params = params.require(:push_subscription).permit(:endpoint, :p256dh_key, :auth_key)

    if subscription = Current.user.push_subscriptions.find_by(endpoint: subscription_params[:endpoint])
      subscription.touch
    else
      Current.user.push_subscriptions.create!(
        subscription_params.merge(user_agent: request.user_agent)
      )
    end

    head :ok
  end

  def destroy
    subscription = Current.user.push_subscriptions.find_by(endpoint: params[:id])

    if subscription
      subscription.destroy
      head :ok
    else
      head :not_found
    end
  end
end
