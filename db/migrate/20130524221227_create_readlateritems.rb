class CreateReadlateritems < ActiveRecord::Migration
  def change
    create_table :readlateritems do |t|

      t.timestamps
    end
  end
end
