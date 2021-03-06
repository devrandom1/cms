require 'spec_helper'
require 'base_objects'

# Force reloads
require 'authored_model'
ActiveSupport::Dependencies.explicitly_unloadable_constants << 'AuthoredModel'

describe Control do
  include BaseObjects

  before :each do
    create_base_objects
    @account = Account.create(:email => "a@b.org", :password => "xxxx", :password_confirmation => "xxxx", :role => "admin")
    @ctl2 = Control.create(:title => 'Control 2', :slug => 'REG1-CTL2', :description => 'x', :program => @reg, :is_key => true, :fraud_related => false)
  end

  it "was not modified by anybody in particular" do
    @ctl.modified_by.should eq(nil)
    @ctl.frequency.should eq(nil)
  end

  it "is creates versions when modified by someone" do
    @ctl.authored_update(@account, :frequency => 11)
    @ctl.reload
    @ctl.frequency.should eq(11)
    @ctl.modified_by.should eq(@account)
    @ctl.versions.size.should eq(1)
    @ctl.versions[0].reify.modified_by_id.should eq(nil)

    @ctl.authored_update(@account, :frequency => 12)
    @ctl.reload
    @ctl.frequency.should eq(12)
    @ctl.modified_by.should eq(@account)
    @ctl.versions.size.should eq(2)
    @ctl.versions[1].reify.modified_by_id.should eq(@account.id)
    @ctl.versions[1].reify.frequency.should eq(11)
    @ctl.versions[0].reify.modified_by_id.should eq(nil)
    @ctl.versions[0].reify.frequency.should eq(nil)
  end

  it "creates a version when deleted" do
    pending
    @ctl2.authored_destroy(@account)
    Version.where(:item_type => "Control", :item_id => @ctl2.id).size.should eq(2)
    Version.where(:item_type => "Control", :item_id => @ctl2.id)[0].reify.modified_by_id.should eq(nil)
    Version.where(:item_type => "Control", :item_id => @ctl2.id)[1].reify.modified_by_id.should eq(@account.id)
    Version.where(:item_type => "Control", :item_id => @ctl2.id)[0].reify.is_destroyed.should be_false
    Version.where(:item_type => "Control", :item_id => @ctl2.id)[1].reify.is_destroyed.should be_true
  end

  it "is associated with descriptor" do
    @ctl.evidence_descriptors.size.should eq(0)
    @ctl.evidence_descriptors << @desc
    @ctl.save
    @ctl.reload
    @ctl.evidence_descriptors.size.should eq(1)
  end

  it "versions relationships" do
    pending
    @ctl.authored_update(@account, :evidence_descriptor_ids => [@desc.id])
    @ctl.save
    @ctl.reload
    # A useless version without author is created (FIXME)
    Version.where(:item_type => "ControlDocumentDescriptor").size.should eq(1)

    @ctl.authored_update(@account, :evidence_descriptor_ids => [])
    @ctl.reload

    debugger
    # Two versions - one with pre-destroy values, and one with timestamps set
    Version.where(:item_type => "ControlDocumentDescriptor").size.should eq(3)
    #ControlDocumentDescriptor::Version.all.size.should eq(3)
    Version.where(:item_type => "ControlDocumentDescriptor").first.modified_by_id.should eq(nil)
    Version.where(:item_type => "ControlDocumentDescriptor").last.modified_by_id.should eq(@account.id)
    ControlDocumentDescriptor.all.size.should eq(0)
    @ctl.authored_update(@account, :evidence_descriptor_ids => [@desc.id])
    @ctl.reload

    # A useless version without author is created (FIXME)
    ControlDocumentDescriptor::Version.all.size.should eq(4)
    @ctl.control_document_descriptors.size.should eq(1)
    @ctl.control_document_descriptors.first.evidence_descriptor.should eq(@desc)
  end
end
