require 'datastreams/properties_datastream'
require_relative './generic_file'
class SeniorThesis < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMixins::RightsMetadata
  include Sufia::ModelMethods
  include Sufia::Noid
  include Sufia::GenericFile::Permissions

  has_metadata :name => "properties", :type => PropertiesDatastream
  has_metadata :name => "descMetadata", :type => SeniorThesisMetadataDatastream

  has_many :generic_files, :property => :is_part_of

  delegate_to(
    :descMetadata,
    [
      :title,
      :created,
      :description,
      :contributor,
      :creator,
      :date_uploaded,
      :date_modified,
      :available,
      :publisher,
      :bibliographic_citation,
      :source,
      :language,
      :archived_object_type,
      :content_format,
      :extent,
      :requires,
      :subject
    ],
    unique: true
  )
  delegate_to(
    :descMetadata,
    [
      :contributor
    ]
  )
  delegate_to :properties, [:relative_path, :depositor], :unique => true
  validates :title, presence: true

  before_save {|obj| obj.archived_object_type = self.class.to_s }

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc["noid_s"] = noid
    return solr_doc
  end

  attr_accessor :thesis_file, :visibility

  def current_thesis_file
    generic_files.first
  end

  #def set_visibility(visibility)
  #  logger.error("Visibility:#{visibility.inspect}")
  #  #require debugger; debug ; true
  #  # only set explicit permissions
  #  case visibility
  #    when "open"
  #      self.datastreams["rightsMetadata"].permissions({:group=>"public"}, "read")
  #    when "ndu"
  #      self.datastreams["rightsMetadata"].permissions({:group=>"registered"}, "read")
  #      self.datastreams["rightsMetadata"].permissions({:group=>"public"}, "none")
  #    when "restricted"
  #      self.datastreams["rightsMetadata"].permissions({:group=>"registered"}, "none")
  #      self.datastreams["rightsMetadata"].permissions({:group=>"public"}, "none")
  #  end
  #end

end
