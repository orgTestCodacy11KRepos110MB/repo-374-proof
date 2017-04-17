require 'test_helper'

class TokenTest < ActiveSupport::TestCase
  # Utility variables
  @@token_from_encoded_data = {
    username: 'johnsmith',
    password: 'password'
  }

  @@token_from_data = {
    user_id: 1
  }

  # Utility methods
  def exp_removed(data)
    # Remove expiration date from hash
    d = data.clone
    d.delete(:exp)
    d
  end

  def test_create_token_from_data
    token = Proof::Token.from_data(@@token_from_data, false)
    assert_equal @@token_from_data, token.data
    assert_equal false, token.expired?
    assert_equal 'HS256', token.algorithm
  end

  def test_create_token_from_data_custom_exp
    key = Rails.application.secrets.secret_key_base
    exp = 2.days.from_now.to_i
    token = Proof::Token.from_data(@@token_from_data, true, key, 'HS256', exp)
    assert_equal @@token_from_data, exp_removed(token.data)
    assert_equal false, token.expired?
    assert_equal exp, token.expiration_date
  end

  def test_create_token_from_data_custom_exp_expired
    key = Rails.application.secrets.secret_key_base
    exp = 2.days.ago.to_i
    token = Proof::Token.from_data(@@token_from_data, true, key, 'HS256', exp)
    assert_equal @@token_from_data, exp_removed(token.data)
    assert_equal true, token.expired?
    assert_equal exp, token.expiration_date
  end

  def test_create_token_from_encoded
    # Pre-encoded token generated from Token class defaults and @@data
    assert_raise JWT::ExpiredSignature do
      token = Proof::Token.from_token('eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6ImpvaG5zbWl0aCIsInBhc3N3b3JkIjoicGFzc3dvcmQiLCJleHAiOjE0Mzc1Mjc3Mjh9.GXmzrexiyYaRGnKJ7Mv7HFvZTm4JwgJ8uCYQ3DN941M')
      assert_equal @@token_from_encoded_data, exp_removed(token.data)
      assert_equal true, token.expired?
      assert_equal 'HS256', token.algorithm
    end
  end
end
