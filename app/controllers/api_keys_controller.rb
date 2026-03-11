class ApiKeysController < ApplicationController
  def create
    @api_key = Current.user.api_keys.build(api_key_params)

    if @api_key.save
      redirect_to profile_path, notice: "API key created successfully."
    else
      redirect_to profile_path, alert: "Failed to create API key: #{@api_key.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @api_key = Current.user.api_keys.find(params[:id])
    @api_key.destroy
    redirect_to profile_path, notice: "API key deleted successfully."
  end

  private

  def api_key_params
    params.require(:api_key).permit(:name)
  end
end
