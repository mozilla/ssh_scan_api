class CreateScanTable < ActiveRecord::Migration[5.1]
  def change
  	create_table :scans do |t|
  	  t.string :scan_id
      t.string :target
      t.integer :port
      t.string :state
      t.string :worker_id
    end
  end
end