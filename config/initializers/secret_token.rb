# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# Sosol::Application.config.secret_token = ENV["SECRET_TOKEN"].presence || '57cd3c931f93abfd5cbee125c6ea73fbfc516574939a73af7edb6d0ca70fddad159b3df9eea95ce1f19dac989816fea6b2cd4b28971aa7c7b868c26a25cf4267'
Sosol::Application.config.secret_key_base = ENV['SECRET_KEY_BASE'].presence || '849aeaa64c43c7cdd5bf038a7821509432a3169ae19854042840037c4dfe0609bad09754f9b7b8663897414b0c44ed88e3cb2f1b207463f132e7e3917c3dba8c'
