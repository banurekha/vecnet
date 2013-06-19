# Vecnet Metadata Catalog

This application provides the [Vecnet Metadata Catalog](http://dl-vecnet.crc.nd.edu).
It handles the curation and indexing of the data generated by the Vecnet [cyberinfrastructure](http://vecnet-web.crc.nd.edu/).

## Dependencies

 * [Fedora Commons](http://fedora-commons.org/) 3.6
 * Solr 4.2
 * Redis (version?)
 * Postgresql or other SQL database
 * nginx
 * [chruby](https://github.com/postmodern/chruby) Ruby version manager

## Deployment

To deploy to QA:

    cap qa deploy

## Other server admin tasks

To rebuild the Fedora object store:

    sudo service tomcat6 stop
    cd /opt/fedora/server/bin
    sudo FEDORA_HOME=/opt/fedora CATALINA_HOME=/usr/share/tomcat6 ./fedora-rebuild.sh
    # choose option 1 to rebuild the resource index
    sudo FEDORA_HOME=/opt/fedora CATALINA_HOME=/usr/share/tomcat6 ./fedora-rebuild.sh
    # choose option 2 to rebuild the SQL database
    sudo service tomcat6 start

To resolarize everything...it will take a LONG time to complete.

    chruby 1.9.3-p392
    RAILS_ENV=qa bundle exec rake solrizer:fedora:solrize_objects

To load and build the MeSH trees run. This will run for a while (~0.5--1 hours)

    chruby 1.9.3-p392
    RAILS_ENV=qa bundle exec rake vecnet:import:mesh_subjects vecnet:import:eval_mesh_trees
