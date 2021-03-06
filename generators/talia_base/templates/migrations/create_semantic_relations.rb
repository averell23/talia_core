# Copyright (c) 2010 Net7 SRL, <http://www.netseven.it/>
# This Software is released under the terms of the MIT License
# See LICENSE.TXT for the full text of the license.

class CreateSemanticRelations < ActiveRecord::Migration
  def self.up
    create_table :semantic_relations do |t|
      t.timestamps
      t.references :object, :polymorphic => true, :null => false
      t.references :subject, :class_name => 'ActiveSource', :null => false
      t.string :predicate_uri, :null => false
    end
    
    add_index :semantic_relations, :predicate_uri, :unique => false
    add_index :semantic_relations, :subject_id, :unique => false
    add_index :semantic_relations, :object_id, :unique => false
  end

  def self.down
    drop_table :semantic_relations
  end
end
