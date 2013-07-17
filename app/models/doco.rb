# Procssing of Docos table records used for Text and Translation Documentation
class Doco < ActiveRecord::Base
  validates_presence_of :category, :line, :description, :note, :preview # remove URL required per Josh :url
  validate :line_positive_and_gt_zero
  
  # - to contain detail documentation data
  # - see Doco.doc_tree for how used
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
  
  # - selects all the documenation records from the 'docos' table for 'docotype' as @+all_docos+
  #   - ordered by category, line
  # - *Args*    :
  #   - +docotype+ -> type of documentation records to pull from table - either 'text' or 'translation'
  # - *Returns* :
  #   - DocoNode for each documentation category using doc_tree
  def self.build_doco(docotype)
    @all_docos = self.find(:all, :conditions => {:docotype => docotype}, :order => "category ASC, line ASC")
    doco_elements = doc_tree
    
    #doco_template = IO.read(File.join(Rails.root, ['data','templates'],"docotemplate.haml"))
    
    #haml_engine = Haml::Engine.new(doco_template)
    
    #open(File.join(Rails.root, ['app','views', 'docos'],"documentation.html.erb"),'w') {|file|
    #open(File.join(Rails.root, ['public','cache'],"documentation.html.erb"),'w') {|file|
    #         file.write(haml_engine.render(Object.new, :doco_elements => doco_elements)) }
    #FileUtils.copy("#{Rails.root}/public/cache/documentation.html.erb", "#{Rails.root}/app/views/docos/documentation.html.erb")
    return doco_elements
  end
  
  # loops through all the 'docos' table records selected in build_doco - ordered by category, line
  # - creates a DocoNode for each unique documentation category on the 'docos' table
  #   - each category DocoNode contains children 
  #     - each child is a DocoNode that contains detail documentation data from each 'docos' record
  # - *Args*    :
  #   - @+all_docos+ -> from build_doco
  # - *Returns* :
  #   - DocoNode parents(category) and children(each table record)
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
  
  # line number validation for docos record
  def line_positive_and_gt_zero
    errors.add(:line, "Line number must be a positive number and greater than 0") if line.blank? || line.to_f < 0.01
  end
  
end
