default = MasterCommunity.create(name: 'PE', friendly_name: 'PE Master', description: 'Master Papyrological Editor Community', allows_self_signup:true)
default.is_default = true
default.save!
