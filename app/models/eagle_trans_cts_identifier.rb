class EagleTransCTSIdentifier < EpiTransCTSIdentifier   
  
  TEMPORARY_COLLECTION = 'eagle'

  def preprocess_for_finalization
    # what we want to do:
    # send the document back to the agent
    if self.status == 'finalizing-preprocessed'
      return false
    else
      document = self.xml_content
      begin
        # parse agent from content
        # send post of content
      rescue Exception => e
        Rails.logger.error("Error updating passage: ",e)
        raise e
      else
        self.status = "finalizing-preprocessed" # TODO check this 
      end
      return true
    end
  end
  
  
end
