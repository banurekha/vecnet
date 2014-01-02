require Curate::Engine.root.join('app/controllers/application_controller')
class ApplicationController < ActionController::Base

  before_filter :decode_user_if_pubtkt_present

  helper_method :current_user, :user_signed_in?, :user_login_url, :user_logout_url

  def decode_user_if_pubtkt_present
    # use authenticate instead of authenticate! since we
    # do not raise an error if there is a problem with the pubtkt.
    # in that case we make the current user nil
    request.env['warden'].authenticate(:pubtkt)
    @current_user = request.env['warden'].user.nil? ? nil : request.env['warden'].user.uid
  end

  # provide the "devise API" for 'user'

  def current_user
    return User.find_by_uid(@current_user) unless @current_user.nil?
    nil
  end

  def user_signed_in?
    current_user != nil
  end

  def authenticate_user!(opts={})
    throw(:warden, opts) unless user_signed_in?
  end

  def user_session
    current_user.uid && session
  end

  # path helpers, since pubtkt passes the return url as a parameter

  def user_login_url(back=nil)
    back = root_path unless back
    redirect_params = { back: back }
    "#{Rails.configuration.pubtkt_login_url}?#{redirect_params.to_query}"
  end

  def user_logout_url
    Rails.configuration.pubtkt_logout_url
  end

  protected
  def agreed_to_terms_of_service!
    return false unless current_user
    return current_user
  end
end
