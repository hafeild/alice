# frozen_string_literal: true
class CreateBootsyImageGalleries < ActiveRecord::Migration
  def change
    create_table :bootsy_image_galleries do |t|
      t.references :bootsy_resource, polymorphic: true
      t.timestamps
    end
  end
end
