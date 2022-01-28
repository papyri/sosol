class AddPrecisionToDecreeDecimal < ActiveRecord::Migration[4.2]
  def self.up
    change_column :decrees, :trigger, :decimal, precision: 5, scale: 2
  end

  def self.down
    change_column :decrees, :trigger, :decimal, precision: nil, scale: nil
  end
end
