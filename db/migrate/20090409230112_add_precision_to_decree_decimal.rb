class AddPrecisionToDecreeDecimal < ActiveRecord::Migration
  def self.up
  	change_column :decrees, :trigger, :decimal, :precision => 5, :scale => 2
  end

  def self.down
  	change_column :decrees, :trigger, :decimal, :precision => nil, :scale => nil
  end
end
