class Analysis < ApplicationRecord
  ## Analysis has...
  ## - name
  ## - summary
  ## - description
  ## - thumbnail_url
  ## - creator (user)
  ## - tags
  ## - web_resources
  ## - examples
  ## - attachments

  include Bootsy::Container

  # after_destroy :reload_connections

  belongs_to :creator, class_name: "User"
  has_and_belongs_to_many :tags
  has_and_belongs_to_many :web_resources
  has_and_belongs_to_many :examples
  has_and_belongs_to_many :assignments
  has_and_belongs_to_many :software, after_remove: :reload_and_save

  # has_and_belongs_to_many :datasets
  # has_and_belongs_to_many :analyses

  has_and_belongs_to_many :attachments


  ## Ensure the presence of required fields. 
  validates :name, presence: true, length: {maximum: 200}, 
    uniqueness: {case_sensitive: false}
  validates :summary, presence: true
  validates :description, presence: true

  ## For search.
  searchable do
    text :name, :summary, :description

    text :software do
      software.map{|a| "#{a.name} #{a.summary} #{a.description}"} 
    end


    text :tags do
      tags.map{|tag| tag.text}
    end

    text :web_resources do
      web_resources.map{|wr| "#{wr.url.gsub('/', ' ')} #{wr.description}"} 
    end

    text :examples do
      examples.map{|example| "#{example.title} #{example.summary} #{example.description}"}
    end

    text :attachments do
      attachments.map{|a| "#{a.file_attachment_file_name} #{a.description}"}
    end

    ## For scoping and faceting.
    integer :creator_facet do 
      creator_id
    end
  end

  def delink
    tags.clear
    web_resources.clear
    examples.clear
  end

  def reload_connections
    [assignments, software, tags, web_resources, examples].each do |connectionSet|
      connectionSet.each do |connection|
        #connection.analyses.delete(self)
        # connection.reload
        connection.analyses.reload
        connection.save!
        # connection.reindex
      end
    end
  end

  def reload_and_save(model)
    model.reload
    model.save!
  end
end
