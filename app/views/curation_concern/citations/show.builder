xml.metadata("xmlns:dc" => "http://purl.org/dc/elements/1.1/",
             "xmlns:dcterms" => "http://purl.org/dc/terms/",
             "xmlns:dwc" => "http://rs.tdwg.org/dwc/terms/",
             "xmlns:vn" => "https://dl.vecnet.org/") do

  xml.tag!("vn:identifier", curation_concern.noid)
  xml.tag!("vn:content_version", curation_concern.current_version_just_id)
  tag_each(xml, "dc:identifier", curation_concern.identifier)

  xml.tag!("vn:depositor", curation_concern.depositor)
  xml.tag!("dc:date_uploaded", curation_concern.date_uploaded)
  xml.tag!("dc:date_modified", curation_concern.date_modified)

  xml.tag!("dc:title", curation_concern.title)

  tag_each(xml, "dc:description", curation_concern.description)
  tag_each(xml, "dc:coverage", curation_concern.based_near)
  tag_each(xml, "dc:creator", curation_concern.creator)
  tag_each(xml, "dc:contributor", curation_concern.contributor)
  tag_each(xml, "dc:subject", curation_concern.tag)
  tag_each(xml, "dc:subject", curation_concern.subject)
  tag_each(xml, "dc:rights", curation_concern.rights)
  tag_each(xml, "dc:publisher", curation_concern.publisher)
  tag_each(xml, "dc:date_created", curation_concern.date_created)
  tag_each(xml, "dc:related", curation_concern.related_url)
  tag_each(xml, "dc:language", curation_concern.language)
  tag_each(xml, "dc:spatial", curation_concern.spatials)
  tag_each(xml, "dc:temporal", curation_concern.temporals)
  tag_each(xml, "dc:type", curation_concern.resource_type)
  tag_each(xml, "dwc:scientificName", curation_concern.species)
  tag_each(xml, "dc:source", curation_concern.source)
  tag_each(xml, "dc:BibliographicCitation", curation_concern.bibliographic_citation)

  if ! curation_concern.generic_files.nil?
    tag_each(xml, "vn:related_files", curation_concern.generic_files.map { |gf| gf.noid })
  end
end