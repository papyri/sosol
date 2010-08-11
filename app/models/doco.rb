class Doco < ActiveRecord::Base
  validates_presence_of :category, :line, :description, :note, :preview # remove URL required per Josh :url
  validate :line_positive_and_gt_zero
  
  class DocoNode
    attr_accessor :children, :category, :description, :preview, :leiden, :xml, :url, :urldisplay, :note
    
    def initialize
      @children = Array.new
      @category = ''
      @description = ''
      @preview = ''
      @leiden = ''
      @xml = ''
      @url = ''
      @urldisplay = ''
      @note = ''
    end
    
  end
  
  def self.build_doco
    @all_docos = self.find(:all, :order => "category ASC, line ASC")
    doco_elements = doc_tree
    
    #doco_template = IO.read(File.join(RAILS_ROOT, ['data','templates'],"docotemplate.haml"))
    
    #haml_engine = Haml::Engine.new(doco_template)
    
    #open(File.join(RAILS_ROOT, ['app','views', 'docos'],"documentation.html.erb"),'w') {|file|
    #open(File.join(RAILS_ROOT, ['public','cache'],"documentation.html.erb"),'w') {|file|
    #         file.write(haml_engine.render(Object.new, :doco_elements => doco_elements)) }
    #FileUtils.copy("#{RAILS_ROOT}/public/cache/documentation.html.erb", "#{RAILS_ROOT}/app/views/docos/documentation.html.erb")
    return doco_elements
  end
  
  def self.doc_tree
    root_elements = Array.new
    categ_test = ""
    loop_cnt = 0
    nbr_to_add = @all_docos.length
    
    until loop_cnt == nbr_to_add 
      categ_element = DocoNode.new
      categ_element.category = @all_docos[loop_cnt].category
      categ_test = @all_docos[loop_cnt].category
    
      inside_cnt = loop_cnt
      until inside_cnt == nbr_to_add || categ_test != @all_docos[loop_cnt].category
        example_element = DocoNode.new
        example_element.description = @all_docos[inside_cnt].description
        example_element.preview = @all_docos[inside_cnt].preview
        example_element.leiden = @all_docos[inside_cnt].leiden
        example_element.xml = @all_docos[inside_cnt].xml
        example_element.url = @all_docos[inside_cnt].url
        example_element.urldisplay = @all_docos[inside_cnt].urldisplay
        if @all_docos[inside_cnt].note.nil? 
          example_element.note = "need to add note to documentation"
        else
          example_element.note = @all_docos[inside_cnt].note.gsub("\n", '<br/>')
        end
        categ_element.children << example_element

        loop_cnt+=1
        inside_cnt+=1
      end
    root_elements << categ_element
    end

    return root_elements
    
  end
  
  protected
  
  def line_positive_and_gt_zero
    errors.add(:line, "Line number must be a positive number and greater than 0") if line.blank? || line.to_f < 0.01
  end
  
end
