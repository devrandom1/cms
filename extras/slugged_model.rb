module SluggedModel
  def self.included(model)
    model.extend(ClassMethods)
  end

  module ClassMethods
    def slugfilter(prefix)
      if !prefix.blank?
        where("#{table_name}.slug LIKE ?", "#{prefix}%").order(:slug)
      else
        order(:slug)
      end
    end

    def slugtree(items)
      st = SlugTree.new("")
      items.each { |item| st.insert(item) }
      st
    end
  end

  class SlugTree
    attr_accessor :prefix, :object, :parent

    def initialize(prefix, parent=nil)
      @prefix = prefix
      @parent = parent

      @object = nil
      @children = {}
    end

    def insert(item)
      raise "Bad child slug: #{item.slug}" if !item.slug.starts_with?(@prefix)

      next_path = item.slug[@prefix.size..-1]
      next_step = next_path.split(/(?=\.|-|\(|\))/)[0]

      if next_step.blank?
        # Replace current node object
        @object = item
      else
        if !@children[next_step]
          @children[next_step] = SlugTree.new(@prefix + next_step, parent=self)
        end
        @children[next_step].insert(item)
      end
    end

    def first_level_descendents
      @children.map do |_, child|
        child.object.nil? ? child.first_level_descendents : child
      end.flatten
    end

    def first_level_descendents_with_step
      first_level_descendents.
        map { |node| [node.prefix[prefix.size..-1], node] }.
        sort_by { |k,_| k.split(/(\d+)/).map { |s| [s.to_i, s] } }
    end
  end

private
  def upcase_slug
    self.slug = slug.upcase
  end

  def validate_slug
    upcase_slug
    return unless parent
    if slug.start_with?(parent.slug)
      true
    else
      errors.add(:slug, "control slug must start with parent's slug #{parent.slug}")
    end
  end
end
