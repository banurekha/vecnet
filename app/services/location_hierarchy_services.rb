class LocationHierarchyServices
  attr_accessor :file, :earth
  def initialize(file="/Users/blakshmi/projects/vecnet/lib/geoname_tree.txt")
    @file = file
    @earth = '6295630'
  end

  # used
  def process_all_geoname_hierachy
    File.open(@file) do |f|
      f.each_line do |line|
        tree_with_geoid = line.strip.split('|')
        begin
          geoname_id = tree_with_geoid.first
          trees = tree_with_geoid - [geoname_id]
          trees.each do |tree|
            tree = tree.split.include?(@earth) ? tree : nil
            GeonameHierarchy.find_or_create(geoname_id, tree)
          end
        rescue Exception => e
          logger.error("#{e.inspect}")
          puts e.inspect
        end
      end
    end
  end

  def eval_tree(tree)
    geoname_ids=tree.split('.')
    geonames = geoname_ids.map{|id| Geoname.find(id).name}
    return geonames.join(';')
  end

  #Yet to create this service
  #def resolve_names(geoname_id)
  #  GeonameDetail.create!( :geoname_id => geoname_id,
  #                            :name => Geoname.find(geoname_id).name,
  #                            :countryname=>eval_country_name(geoname_id),
  #                            :admin1name=>eval_admin1_name(geoname_id)
  #  )
  #
  #end

  # used
  def self.find_hierarchy(geo_name_id)
    tree_id, tree_names= GeonameWebServices::Hierarchy.hierarchy(geo_name_id)
    #puts "tree: #{tree_id}, Names:#{tree_names}"
    GeonameHierarchy.find_or_create(geo_name_id,tree_id)
    return tree_id, tree_names
  end

  # used
  def self.get_geoname_ids(locations)
    geonames_ids = {}
    unless locations.blank?
      locations.each do |location|
        id = self.location_to_geonameid(location)
        geonames_ids[location] = id if id
      end
    end
    return geonames_ids
  end

  # new
  def self.name_to_solr_hierarchy(location)
    id = self.location_to_geonameid(location)
    return [] unless id
    h = GeonameHierarchy.find_by_geoname_id(id)
    return [] unless h
    h_with_earth = h.hierarchy_tree_name
    if h_with_earth.nil?
      _, h_with_earth = self.find_hierarchy(id)
    end
    tree = h_with_earth.gsub(';', ':').gsub('Earth:', '')
    self.get_solr_hierarchy_from_tree(tree)
  end

  # used
  def self.geoname_location_format(location)
    location_memo = CacheGeonameSearch.find_by_geo_location(location)
    if location_memo
      return location_memo.geo_location
    end
    q = location.split(",").first
    hits = GeonameWebServices::Search.search(q)
    hits.each do |result|
      result_place = result[:label].split(",").first
      if result_place == q
        CacheGeonameSearch.find_or_create(location, result[:value])
        return result[:label]
      end
    end
    logger.error("Could not find any geoname for given location: #{location}")
    return location
  end

  def self.location_to_geonameid(location)
    location_memo = CacheGeonameSearch.find_by_geo_location(location)
    if  location_memo
      return location_memo.geoname_id
    end
    q = location.split(",").first
    hits = GeonameWebServices::Search.search(q)
    # first look for an exact match for "place,admin1,country"
    # remove commas since sometimes an second comma is inserted even when there is no admin1
    hits.each do |result|
      if result[:label].gsub(/[\s,]/,'').eql?(location.gsub(/[\s,]/,''))
        CacheGeonameSearch.find_or_create(location, result[:value])
        return result[:value]
      end
      return nil
    end
    # now look for something with the same place name
    # This does not try to find the most specific place with the name, though
    hits.each do |result|
      result_place = result[:label].split(",").first
      if result_place == q
        CacheGeonameSearch.find_or_create(location, result[:value])
        return result[:value]
      end
    end
    nil
  end

  # returns the given tree string as well as all parent tree strings for it
  #
  # used
  def self.get_solr_hierarchy_from_tree(tree)
    hierarchies = []
    current_hierarchy = tree;
    loop do
      hierarchies << "#{current_hierarchy}"
      current_hierarchy = current_hierarchy.rpartition(':').first
      break if current_hierarchy.empty?
    end
    hierarchies.reverse
  end
end
