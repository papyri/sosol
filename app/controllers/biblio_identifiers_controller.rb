# Controller for all actions concerning the handling of bibliographical data, such as edit and update
class BiblioIdentifiersController < IdentifiersController
  before_action :authorize
  before_action :ownership_guard, only: %i[update updatexml]

  # Retrieves bibliography object from database and displays all values in a entry mask
  # Assumes that incoming post respectively get parameters contain a valid biblio identifier id
  # Side effect on +@identifier+ and +@is_editor_view+
  def edit
    @is_editor_view = true
    find_identifier
  end

  # Retrieves bibliography object from database and updates its values from incoming post data, saves comment
  # Redirects back to the editor (see action edit, above)
  # Assumes that incoming post request contains new values for the biblio record that should be written back to EpiDoc
  # Side effect on +@identifier+ and +flash+
  # Writes to database and git repository, clears publication cache
  def update
    find_identifier
    begin
      params.permit!
      commit_sha = @identifier.set_epidoc(params[:biblio_identifier].to_h, params[:comment])

      expire_publication_cache
      generate_flash_message
    rescue Epidocinator::ParseError => e
      flash[:error] = "Error updating file: #{e.to_str}. This file was NOT SAVED."
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   action: :edit)
      return
    end

    save_comment(params[:comment].to_s, commit_sha)

    flash[:expansionSet] = params[:expansionSet].to_s

    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 action: :edit)
  end

  # Retrieves bibliography record by +params[:id]+ and puts a preview to stage
  # Side effect on +@identifier+ and +@is_editor_view+
  def preview
    @is_editor_view = true
    find_identifier
  end

  protected

  # Copypasted from HGVMetaIdentifiersController
  def generate_flash_message
    flash[:notice] = 'File updated.'
    if %w[new editing].include? @identifier.publication.status
      flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
    end
  end

  # Copypasted from HGVMetaIdentifiersController
  def save_comment(comment, commit_sha)
    if !comment.nil? && comment.strip != ''
      @comment = Comment.new({ git_hash: commit_sha, user_id: @current_user.id,
                               identifier_id: @identifier.id, publication_id: @identifier.publication_id, comment: comment, reason: 'commit' })
      @comment.save
    end
  end

  # Retrieves biblio identifier from database by id which it takes from the incoming post stream
  # Assumes that post data contains biblio identifier id
  # Side effect on +@identifier+
  def find_identifier
    @identifier = BiblioIdentifier.find(params[:id].to_s)
  end
end
