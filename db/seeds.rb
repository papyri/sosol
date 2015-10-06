default = MasterCommunity.create(name: 'SoSOL', friendly_name: 'SoSOL', description: 'Default Master Community', allows_self_signup:true)
default.is_default = true
default.save!
