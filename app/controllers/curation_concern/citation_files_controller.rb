class CurationConcern::CitationFilesController < CurationConcern::BaseController

  respond_to(:html, :xml, :json, :endnote)

  def attach_action_breadcrumb
    add_breadcrumb 'Home', root_path
    case request.referer
      when /dashboard/
        add_breadcrumb 'Dashboard', dashboard_index_path
      when /catalog/
        add_breadcrumb 'Back to Search results', request.referer
    end
    add_edit_breadcrumb
  end

  def add_edit_breadcrumb
    case action_name
      when 'show'
        add_breadcrumb curation_concern.human_readable_type, request.path
      when 'new', 'create'
        add_breadcrumb "Parent #{parent.human_readable_type}", curation_concern_citation_path(parent)
        add_breadcrumb "New #{curation_concern.human_readable_type}", request.path
      else
        add_breadcrumb "Parent #{parent.human_readable_type}", edit_curation_concern_citation_path(parent)
        add_breadcrumb action_name.titleize, request.path
    end
  end

  before_filter :parent
  before_filter :curation_concern
  load_resource :parent, class: "ActiveFedora::Base"

  def parent
    @parent ||=
    if params[:id]
      curation_concern.batch
    else
      ActiveFedora::Base.find(namespaced_parent_id,cast: true)
    end
  end
  helper_method :parent

  def namespaced_parent_id
    Sufia::Noid.namespaceize(params[:parent_id])
  end
  protected :namespaced_parent_id

  def curation_concern
    @curation_concern ||=
    if params[:id]
      CitationFile.find(params[:id])
    else
      CitationFile.new(params[:citation_file])
    end
  end

  def action_name_for_authorization
    (action_name == 'versions' || action_name == 'rollback') ? :edit : super
  end
  protected :action_name_for_authorization

  def new
    respond_with(curation_concern){ |wants|
      wants.html {}
    }
  end

  def create
    curation_concern.batch = parent
    actor.create!
    redirect_to edit_curation_concern_citation_path(parent)
    flash[:curation_concern_pid] = curation_concern.pid
  rescue ActiveFedora::RecordInvalid
    respond_with([:curation_concern, curation_concern]) { |wants|
      wants.html { render 'new', status: :unprocessable_entity }
    }
  end


  def show
    respond_with(curation_concern){|format|
      format.endnote { render :text => curation_concern.endnote_export }
    }
  end

  def edit
    respond_with(curation_concern)
  end

  def update
    actor.update!
    redirect_to edit_curation_concern_citation_path(parent)
  rescue ActiveFedora::RecordInvalid
    respond_with([:curation_concern, curation_concern]) { |wants|
      wants.html { render 'edit', status: :unprocessable_entity }
    }
  end

  def versions
    respond_with(curation_concern)
  end

  def rollback
    actor.rollback
    respond_with([:curation_concern, curation_concern])
  end

  def destroy
    title = curation_concern.to_s
    curation_concern.destroy
    flash[:notice] = "Deleted #{title}"
    redirect_to redirect_to_dashboard
  end

  include Morphine
  register :actor do
    CurationConcern.actor(curation_concern, current_user, params[:citation_file])
  end
  private
    def show_breadcrumbs?
      true
    end

    def redirect_to_dashboard
      query_params = session[:search] ? session[:search].dup : {}
      query_params.delete :counter
      query_params.delete :total
      controller=query_params.delete :controller
      if controller.eql?("admin_dashboard")
        return admin_dashboard_index_path(query_params)
      else
        return dashboard_index_path(query_params)
      end
    end
end
