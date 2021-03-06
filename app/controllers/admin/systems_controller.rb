class Admin::SystemsController < ApplicationController
  layout "admin"
  include ManyHelper

  # List Systems
  def index
    @systems = System.order(:slug)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @systems }
    end
  end

  # Show a system
  def show
    @system = System.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @system }
    end
  end

  # New system form
  def new
    @system = System.new

    # A couple of lines for new docs
    @system.documents << Document.new
    @system.documents << Document.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @system }
    end
  end

  # Edit system form
  def edit
    @system = System.find(params[:id])

    # A couple of lines for new docs
    @system.documents << Document.new
    @system.documents << Document.new
  end

  # Create a system
  def create
    documents_params = params[:system].delete("document") || {}
    @system = System.new(params[:system])

    # Accumulate results
    results = []
    documents_params.each_pair do |index, doc_params|
      next if doc_params["link"].blank?
      # Create / delete / update attached doc
      # TODO: find existing doc, gdoc integration
      doc = @system.documents.create(doc_params)
      results << doc
    end

    results << @system.save

    respond_to do |format|
      if results.all?
        format.html { redirect_to(edit_system_path(@system), :notice => 'System was successfully created.') }
        format.xml  { render :xml => @system, :status => :created, :location => @system }
      else
        flash.now[:error] = 'Could not create.'
        format.html { render :action => "new" }
        format.xml  { render :xml => @system.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Update a system
  def update
    @system = System.find(params[:id])

    # Accumulate results
    results = []
    documents_params = params[:system].delete("document") || {}
    documents_params.each_pair do |index, doc_params|
      next if doc_params["link"].blank?
      is_delete = doc_params.delete("delete") == "1"
      id = doc_params.delete("id")
      # Create / delete / update attached doc
      if id.blank?
        doc = @system.documents.create(doc_params)
        results << doc
      elsif is_delete
        results << @system.document_systems.first(:document_id => id).destroy
        results << Document.first(:id => id).destroy
      else
        results << Document.find(id).update_attributes(doc_params)
      end
    end

    results << @system.update_attributes(params[:system])

    respond_to do |format|
      if results.all?
        format.html { redirect_to(edit_system_path(@system), :notice => 'System was successfully updated.') }
        format.xml  { head :ok }
      else
        flash.now[:error] = 'Could not update.'
        format.html { render :action => "edit" }
        format.xml  { render :xml => @system.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Delete a system
  def destroy
    system = System.find(params[:id])

    success = system.document_systems.destroy &&
        system.system_controls.destroy &&
        system.biz_process_systems.destroy &&
        system.system_sections.destroy &&
        system.destroy

    respond_to do |format|
      format.html { redirect_to(systems_url) }
      format.xml  { head :ok }
    end
  end

  # Many2many relationship to Controls
  def controls
    if request.put?
      post_many2many(:left_class => System, :right_class => Control)
    else
      get_many2many(:left_class => System, :right_class => Control)
    end
  end

  # Many2many relationship to COs
  def sections
    if request.put?
      post_many2many(:left_class => System, :right_class => Section)
    else
      get_many2many(:left_class => System, :right_class => Section)
    end
  end

  # Many2many relationship to Biz Processes
  def biz_processes
    if request.put?
      post_many2many(:left_class => System, :right_class => BizProcess)
    else
      get_many2many(:left_class => System, :right_class => BizProcess)
    end
  end

  def add_person
    @system = System.find(params[:id])
  end
 
  # Another way to attach a biz process
  def create_person
    @system = System.find(params[:id])
    @system_person = SystemPerson.new(params[:system_person])
    @system_person.system = @system
    if @system_person.save
      flash[:notice] = 'Contact was successfully attached.'
      redirect_to edit_system_path(@system)
    else
      flash[:error] = 'Failed' + @system_person.errors.inspect
      redirect_to add_person_system_path(@system_person.person)
    end
  end
 
  # Another way to detach a biz process
  def destroy_person
    sysp = SystemPerson.first(:person_id => params[:person_id], :system_id => params[:id])
    if sysp && sysp.destroy
      flash[:notice] = 'Contact was successfully detached.'
    else
      flash[:error] = 'Failed'
    end
    redirect_to edit_system_path(System.find(params[:id]))
  end

  def clone
    raise "cannot clone without cycle" unless @cycle
    @orig = System.find(params[:id])
    @system = System.new
    @system.title = "Copy of #{@orig.title}"
    @system.slug = "COPY-#{@orig.slug}-#{Time.new.to_i}"
    @system.infrastructure = @orig.infrastructure
    @system.description = @orig.description
    @system.biz_processes += @orig.biz_processes
    @system.sections += @orig.sections
    @orig.system_controls.each do |sc|
      @system.system_controls << SystemControl.new(:control => sc.control, :cycle => @cycle)
    end

    if @system.save
      flash[:notice] = 'System was successfuly cloned.'
      redirect_to edit_system_path(@system)
    else
      flash[:error] = 'Failed' + @system.errors.inspect
      redirect_to systems_path
    end
  end
end
