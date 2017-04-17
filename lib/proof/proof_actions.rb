module Proof

  # @api private
  class Error < StandardError; end

  # Error that will be raised when authorization has failed
  class NotAuthorizedError < Error; end

  module ProofActions
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def proof_actions(options={}, &block)
        options[:authenticatable] ||= :User
        options[:identifier] ||= :email
        options[:password] ||= :password
        options[:authenticate] ||= :authenticate
        options[:set_cookie] ||= false
        options[:expire_token] ||= true
        options[:raise_error] ||= false
        options[:error_json] ||= { error: "Invalid Credentials." }
        options[:block] = nil
        if block_given?
          options[:block] = block
        end
        cattr_accessor :proof_options
        self.proof_options = options
        include Proof::ProofActions::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      def login
        proof_class = self.class.proof_options[:authenticatable].to_s.camelize.constantize
        identifier = self.class.proof_options[:identifier]
        user = proof_class.find_by(identifier => params[identifier])
        if user && user.send(self.class.proof_options[:authenticate], params[self.class.proof_options[:password]])
          auth_token = Proof::Token.from_data({ user_id: user.id }, self.class.proof_options[:expire_token])
          json = { auth_token: auth_token }
          if !self.class.proof_options[:block].nil?
            json = self.class.proof_options[:block].call(user, auth_token)
          end
          if self.class.proof_options[:set_cookie]
            cookies[:user] = { value: json, expires: Time.at(auth_token.expiration_date) }
          end
          render json: json, status: 201
        else
          raise NotAuthorizedError if self.class.proof_options[:raise_error]
          render json: self.class.proof_options[:error_json], status: :unauthorized unless self.class.proof_options[:raise_error]
        end
      end
    end
  end
end
