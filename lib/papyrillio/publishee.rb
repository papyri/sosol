module Papyrillio
  class Publishee
    attr_accessor :label, :print_index, :html, :publication, :user

    def initialize params
      @label       = params[:label]       ? params[:label]       : ''   # e.g. 'SoSOL 2010 4'
      @print_index = params[:print_index] ? params[:print_index] : 0    # 1..n, 0 for all those that cannot be sorted
      @html        = params[:html]        ? params[:html]        : ''   # transformation html
      @publication = params[:publication] ? params[:publication] : nil  # publication object
      @user        = params[:user]        ? params[:user]        : ''   # user name
      
      @hgv_meta_identifier = nil                                        # HgvMetaIdentifier object
    end

    def hgv_meta_identifier
      if @hgv_meta_identifier == nil
         if @publication
           @hgv_meta_identifier = HGVMetaIdentifier.find_by_publication_id(@publication.id)
           @hgv_meta_identifier.get_epidoc_attributes
         end
      end
      @hgv_meta_identifier
    end

  end
end