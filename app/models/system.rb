# A system to be audited
class System < ActiveRecord::Base
  include AuthoredModel
  include SluggedModel

  before_save :upcase_slug

  validates :title, :slug, :presence => true

  # Many to many with Control
  has_many :system_controls
  has_many :controls, :through => :system_controls, :order => :slug

  # Many to many with Section
  has_many :system_sections
  has_many :sections, :through => :system_sections, :order => :slug

  # Many to many with BizProcess
  has_many :biz_process_systems
  has_many :biz_processes, :through => :biz_process_systems, :order => :slug

  # Responsible party
  belongs_to :owner, :class_name => 'Person'

  # Other parties
  has_many :system_persons
  has_many :persons, :through => :system_persons

  # Relevant documentation
  has_many :documents, :through => :document_systems
  has_many :document_systems

  is_versioned_ext

  # Which systems can be attached to a control
  def self.for_control(c)
    order(:slug) #c.systems
  end

  # Which systems can be attached to a control objective
  def self.for_section(co)
    order(:slug)
  end

  # Which systems can be attached to a biz process
  def system_controls_by_process(bp)
    system_controls.where(:control_id => bp.controls)
  end

  # Rolled up state by biz process
  def state_by_process(bp)
    state(:control_id => bp.controls)
  end

  # Rolled up state
  def state(opts = {})
    scs = system_controls.where(opts)
    bad = 0
    count = 0
    res = [:green, ControlState::STATE_WEIGHT[:green]]
    res = scs.inject(res) do |memo, obj|
      count = count + 1
      if !ControlState::STATE_IS_GOOD[obj.state]
        bad = bad + 1
      end
      weight = ControlState::STATE_WEIGHT[obj.state]
      if weight > memo[1]
        [obj.state, weight]
      else
        memo
      end
    end
    return { :state => res[0], :count => count, :bad => bad }
  end

  def display_name
    slug
  end

  # Return ids of related Controls (used by many2many widget)
  def control_ids
    controls.map { |c| c.id }
  end

  # Return ids of related Biz Processes (used by many2many widget)
  def biz_process_ids
    biz_processes.map { |bp| bp.id }
  end

  # Return ids of related Sections (used by many2many widget)
  def section_ids
    sections.map { |co| co.id }
  end
end
