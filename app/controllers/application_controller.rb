require 'dm-rails/middleware/identity_map'
class ApplicationController < ActionController::Base
  before_filter :require_user
  before_filter :regulation_filter_set

  use Rails::DataMapper::Middleware::IdentityMap
  protect_from_forgery

  helper_method :current_user_session, :current_user

  access_control :acl do
    allow :admin
  end

  rescue_from Acl9::AccessDenied do
      flash[:warning] = "You are not authorized to access this page"
      redirect_to root_url
      return false
  end

  private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end
    
    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end
    
    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to login_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to root_url
        return false
      end
    end
    
    def store_location
      session[:return_to] = request.fullpath
    end
    
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    def regulation_filter_set
      regulation_id = params[:regulation][:id] rescue nil
      if !regulation_id.nil?
        if regulation_id == ""
          session[:regulation_id] = nil
        else
          session[:regulation_id] = regulation_id
        end
      end
    end

end
