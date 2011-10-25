class Admin::RegulationsController < ApplicationController
  layout "admin"

  def slug
    respond_to do |format|
      format.js  { render :js => Regulation.get(params[:id]).slug }
    end
  end

  def index
    @regulations = Regulation.all

    respond_to do |format|
      format.html
      format.xml  { render :xml => @regulations }
    end
  end

  def show
    @regulation = Regulation.get(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @regulation }
    end
  end

  def new
    @regulation = Regulation.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @regulation }
    end
  end

  def edit
    @regulation = Regulation.get(params[:id])
  end

  def create
    @regulation = Regulation.new(params[:regulation])
    @regulation.source_document = Document.new(params[:regulation].delete("source_document"))
    @regulation.source_website = Document.new(params[:regulation].delete("source_website"))

    respond_to do |format|
      if @regulation.save
        format.html { redirect_to(edit_regulation_path(@regulation), :notice => 'Regulation was successfully created.') }
        format.xml  { render :xml => @regulation, :status => :created, :location => @regulation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @regulation.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @regulation = Regulation.get(params[:id])

    @regulation.source_document ||= Document.create
    @regulation.source_website ||= Document.create

    results = []
    results << @regulation.source_document.update(params[:regulation].delete("source_document") || {})
    results << @regulation.source_website.update(params[:regulation].delete("source_website") || {})

    @regulation.save if @regulation.dirty?

    results << @regulation.update(params[:regulation])

    respond_to do |format|
      if results.all?
        format.html { redirect_to(edit_regulation_path(@regulation), :notice => 'Regulation was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @regulation.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @regulation = Regulation.get(params[:id])
    @regulation.destroy

    respond_to do |format|
      format.html { redirect_to(regulations_url) }
      format.xml  { head :ok }
    end
  end
end