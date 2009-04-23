class MasterArticle < ActiveRecord::Base
  has_many :articles
  belongs_to :user
  
  class LoadEpidocError < StandardError

	end

  
  def add_meta_article(tm_number)
      
      #create new article
				@meta_article = Article.new
				@meta_article.category = "Meta"
				@meta_article.master_article_id = self.id
				@meta_article.user_id = self.user_id#@current_user.id
				@meta_article.content = "<xml>pig</xml>"
				@meta_article.status = "new"
				@meta_article.save
				#TODO add warning if not saved
				
			#create the metadata for the article	
				@meta = Meta.new()
				@meta.article_id = @meta_article.id
				@meta.user_id = self.user_id # @current_user.id		               
				@meta.save
				#TODO add warning if not saved
        
      #inform the board a new article exist
        board = Board.find_by_category("Meta")
        if board != nil
        	board.articles << @meta_article
        	board.save
        	#TODO add warning if not saved
        	@meta_article.board_id = board.id        
        end
        
        @meta_article.meta_id = @meta.id
        @meta_article.save
        #TODO add warning if not saved
        
        if tm_number != nil && tm_number.strip != ""
        #try to read data
        	begin
        		@meta.load_epidoc_from_tm(tm_number)
        		@meta.save
        	rescue
        		@meta.destroy #if we can't load it destroy it
        		@meta_article.destroy
        		#need to return warning
        		raise LoadEpidocError
        	end
        	
        end
        
        @meta_article.send_status_emails(@meta_article.status)
    
  end
  
  
  
  
  
  
  
  
  
  
  
   def add_transcription_article(tm_number)
				@script_article = Article.new
				@script_article.category = "Transcription"
				@script_article.master_article_id = self.id
				@script_article.user_id = self.user_id#@current_user.id
				@script_article.content = "<xml>none</xml>"
				@script_article.status = "new"
				@script_article.save
				#TODO add warning if not saved
				
				@script = Transcription.new()
				@script.article_id = @script_article.id
        @script.user_id = self.user_id#@current_user.id
        @script.save
        #TODO add warning if not saved
        
        board = Board.find_by_category("Transcription")
        if board != nil
        	board.articles << @script_article
        	board.save
        	#TODO add warning if not saved
        	@script_article.board_id = board.id        
        end        
        
        @script_article.transcription_id = @script.id
        @script_article.save
        #TODO add warning if not saved
        
        if tm_number != nil && tm_number.strip != ""
        #try to read data
        	begin
        		@script.load_epidoc_from_tm(tm_number)
        		@script.save
        	rescue
        		@script.destroy #if we can't load it destroy it
        		@script_article.destroy
        		#need to return warning
        		raise LoadEpidocError        	
        	end
        	
        end
        
        @script_article.send_status_emails(@script_article.status)
        
    end
     
     
    def add_translation_article(tm_number)
				@trans_article = Article.new
				@trans_article.category = "Translation"
				@trans_article.master_article_id = self.id
				@trans_article.user_id = self.user_id
				@trans_article.content = "<xml>none</xml>"
				@trans_article.status = "new"
				@trans_article.save
				#TODO add warning if not saved
				
				@translation = Translation.new()
				@translation.xml_to_translations_ok = true
    		@translation.translations_to_xml_ok = true
				@translation.article_id = @trans_article.id
        @translation.user_id = self.user_id
        @translation.save
        #TODO add warning if not saved
        
        board = Board.find_by_category("Translation")
        if board != nil
        	board.articles << @trans_article
        	board.save
        	#TODO add warning if not saved
        	@trans_article.board_id = board.id        
        end        
        
        @trans_article.translation_id = @translation.id
        @trans_article.save
        #TODO add warning if not saved
        
        if tm_number != nil && tm_number.strip != ""
        #try to read data
        	begin
        		@translation.load_epidoc_from_tm(tm_number)
        		@translation.save
        	rescue
        		@translation.destroy #if we can't load it destroy it
        		@trans_article.destroy        		
        		#need to return warning
        		raise LoadEpidocError 
        	end
        end
        
        @trans_article.send_status_emails(@trans_article.status)
    end
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
end
