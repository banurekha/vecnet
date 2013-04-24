class CurationConcern::BaseController < ApplicationController
  layout 'vecnet'
  include Sufia::Noid # for normalize_identifier method

  before_filter :authenticate_user!, :except => [:show]
  before_filter :agreed_to_terms_of_service!
  prepend_before_filter :normalize_identifier, except: [:index, :new, :create]
  before_filter :curation_concern, except: [:index]
  #load_and_authorize_resource :curation_concern, except: [:index, :new, :create], class: "ActiveFedora::Base"

  attr_reader :curation_concern
  helper_method :curation_concern

  def contributor_agreement
    @contributor_agreement ||= ContributorAgreement.new(curation_concern, current_user, params)
  end
  helper_method :contributor_agreement

  def save_and_add_related_files_submit_value(override_name = action_name)
    verb_name = ['create', 'new'].include?(override_name) ? 'Create' : 'Update'
    "#{verb_name} and Add Related Files..."
  end
  helper_method :save_and_add_related_files_submit_value
end
