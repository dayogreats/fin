module Api
  module V1
    class BaseController < ApplicationController
      include ActionController::MimeResponds
      
      before_action :authenticate_request
      
      private
      
      def authenticate_request
        header = request.headers['Authorization']
        if header
          token = header.split(' ').last
          begin
            @decoded = JWT.decode(token, Rails.application.credentials.jwt_secret_key, true, algorithm: 'HS256')
            @current_user = User.find(@decoded[0]['user_id'])
          rescue JWT::DecodeError
            render json: { error: 'Invalid token' }, status: :unauthorized
          rescue Mongoid::Errors::DocumentNotFound
            render json: { error: 'User not found' }, status: :unauthorized
          end
        else
          render json: { error: 'Token missing' }, status: :unauthorized
        end
      end

      def current_user
        @current_user
      end
    end
  end
end
