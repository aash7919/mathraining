class CreateChaptersSectionsJoinTable < ActiveRecord::Migration
  def change
    create_table :chapters_sections, :id => false do |t|
      t.references :chapter
      t.references :section
    end
  end
end
