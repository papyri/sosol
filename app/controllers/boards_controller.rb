class BoardsController < ApplicationController
  # layout "site"
  # layout "header_footer"
  before_action :authorize
  before_action :check_admin

  # Presents overview for publication.
  def overview
    @board = Board.find(params[:id].to_s)

    if @board.users.find_by(id: @current_user.id) || @current_user.developer
      # return only owner publications
      finalizing_publications = Publication.where(owner_id: @current_user.id, status: 'finalizing')

      @finalizing_publications = finalizing_publications&.collect { |p| p.parent.owner == @board ? p : nil }&.compact
    else
      # dont let them have access
      redirect_to dashboard_url
      nil
    end
  end

  def find_member
    @board = Board.find(params[:id].to_s)
  end

  # Adds the user to the board member list.
  def add_member
    @board = Board.find(params[:id].to_s)
    user = User.find_by(name: params[:user_name].to_s)

    if @board.users.find_by(id: user.id).nil?
      @board.users << user
      @board.save
    end

    redirect_to action: 'edit', id: @board.id
  end

  # Removes a member from the board member list.
  def remove_member
    user = User.find(params[:user_id].to_s)

    @board = Board.find(params[:id].to_s)
    @board.users.delete(user)
    @board.save

    redirect_to action: 'edit', id: @board.id
  end

  # GET /boards
  # GET /boards.xml
  def index
    # @boards = Board.all
    @boards = Board.ranked

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @boards }
    end
  end

  # GET /boards/1
  # GET /boards/1.xml
  def show
    @board = Board.find(params[:id].to_s)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @board }
    end
  end

  # GET /boards/new
  # GET /boards/new.xml
  def new
    @board = Board.new

    # don't let more than one board use the same identifier class
    @available_identifier_classes = Array.new(Identifier::IDENTIFIER_SUBCLASSES)

    # existing_boards = Board.all
    # existing_boards.each do |b|
    #  @available_identifier_classes -= b.identifier_classes
    # end

    @board.community_id = params[:community_id].to_s if params[:community_id]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @board }
    end
  end

  # GET /boards/1/edit
  def edit
    @board = Board.find(params[:id].to_s)
  end

  # POST /boards
  # POST /boards.xml
  def create
    @board = Board.new(board_params)

    @board.identifier_classes = []

    # let them choose as many ids as they want
    Identifier::IDENTIFIER_SUBCLASSES.each do |identifier_class|
      if params.key?(identifier_class) && params[identifier_class].to_s == '1'
        @board.identifier_classes << identifier_class
      end
    end

    # put the new board in last rank
    if @board.community_id
      @board.rank = Board.ranked_by_community_id(@board.community_id).count + 1 #+1 since ranks start at 1 not 0. Also new board has not been added to count until it gets saved.
    else
      # @board.rank = Board.count()  + 1 #+1 since ranks start at 1 not 0. Also new board has not been added to count until it gets saved.
      @board.rank = Board.ranked.count + 1 #+1 since ranks start at 1 not 0. Also new board has not been added to count until it gets saved.
    end
    # just let them choose one identifer class
    # @board.identifier_classes << params[:identifier_class]

    mailers = YAML.load_file(File.join(Rails.root, %w[config board_mailers.yml]))[:mailers] || { default: [] }
    mailers = if @board.community && mailers[@board.community.type]
                mailers[@board.community.type]
              else
                mailers[:default]
              end
    mailers.each do |m|
      m[:board_id] = @board.id
      e = Emailer.new(m)
      if e.save
        @board.emailers << e
      else
        flash[:warning]  = 'Unable to save mailer'
      end
    end

    if @board.save
      flash[:notice] = 'Board was successfully created.'
      redirect_to action: 'edit', id: @board.id
    else
      @board.emailers.each(&:destroy)
      flash[:error] = "Board creation failed. #{@board.errors.to_a}"
      redirect_to dashboard_url
    end
  end

  # PUT /boards/1
  # PUT /boards/1.xml
  def update
    @board = Board.find(params[:id].to_s)

    respond_to do |format|
      if params[:board].present? && @board.update(board_params)
        flash[:notice] = 'Board was successfully updated.'
        format.html { redirect_to(@board) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @board.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /boards/1
  # DELETE /boards/1.xml
  def destroy
    @board = Board.find(params[:id].to_s)
    @board.destroy

    respond_to do |format|
      format.html { redirect_to(boards_url) }
      format.xml  { head :ok }
    end
  end

  # *Returns* array of boards sorted by rank. Lowest rank (highest priority) first.
  # If community_id is given then the returned boards are only for that community.
  # If no community_id is given then the "sosol" boards are returned.
  def rank
    if params[:community_id]
      @boards = Board.ranked_by_community_id(params[:community_id].to_s)
      @community_id = params[:community_id].to_s
    else
      # default to sosol boards
      @boards = Board.ranked
    end
  end

  # Sorts board rankings by given array of board id's and saves new rankings.
  def update_rankings
    @boards = if params[:community_id].blank?
                # default to sosol boards
                Board.ranked
              else
                Board.ranked_by_community_id(params[:community_id].to_s)
              end

    # @boards = Board.all

    rankings = params[:ranking].to_s.split(',')

    rank_count = 1
    rankings.each do |rank_id|
      @boards.each do |board|
        next unless board.id == rank_id.to_i

        board.rank = rank_count
        board.save!
        break
      end
      rank_count += 1
    end

    if params[:community_id].blank?
      # default to sosol boards
      redirect_to action: 'index'
    else
      redirect_to controller: 'communities', action: 'edit', id: params[:community_id].to_s
    end
    nil
  end

  def send_board_reminder_emails
    addresses = []

    if params[:community_id].to_s == ''
      boards = Board.ranked
    else
      boards = Board.ranked_by_community_id(params[:community_id].to_s)
      community = Community.find_by(id: params[:community_id].to_s)
    end

    body_text = 'Greetings '
    body_text += "#{community.name} " if community
    time_str = Time.zone.now.strftime('%Y-%m-%d')
    body_text += "Board Members, as of #{time_str}, "
    boards.each do |board|
      # grab addresses for this board
      board.users.each do |board_user|
        addresses << board_user.email
      end

      body_text += "\n#{board.name} has "

      # find all pubs that are still in voting phase
      voting_publications = board.publications.collect { |p| p.status == 'voting' ? p : nil }.compact
      body_text += if voting_publications
                     voting_publications.length.to_s
                   else
                     'no'
                   end
      body_text += ' publications requiring voting action, '

      body_text += ' and '

      approved_publications = board.publications.collect { |p| p.status == 'approved' ? p : nil }.compact
      body_text += if approved_publications
                     approved_publications.length.to_s
                   else
                     'no'
                   end
      body_text += ' approved publications waiting to be finalized.  '

      completed_publications = board.publications.collect do |p|
        p.status == 'committed' || p.status == 'archived' ? p : nil
      end.compact

      body_text += if completed_publications
                     completed_publications.length.to_s
                   else
                     'No'
                   end
      body_text += ' publications have been committed.'

      subject_line = ''
      subject_line += "#{community.name} " if community
      subject_line += 'Board Publication Status Reminder '

      addresses.each do |address|
        next unless address && address.strip != ''

        begin
          EmailerMailer.general_email(address, subject_line, body_text).deliver_now
        rescue StandardError => e
          Rails.logger.error("Error sending email: #{e.class}, #{e}")
        end
      end
    end

    flash[:notice] = if community
                       "Notifications sent to all #{community.name} board members."
                     else
                       'Notifications sent to all PE board members.'
                     end
    redirect_to dashboard_url
  end

  def confirm_destroy
    @board = Board.find(params[:id].to_s)
  end

  private

  # Ensures user has admin rights to view page. Otherwise returns 403 error.
  def check_admin
    if @current_user.nil? || !@current_user.admin
      render file: Rails.root.join('public', '403.html'), status: '403', layout: false, formats: [:html]
    end
  end

  def board_params
    params.require(:board).permit(:title, :category, :identifier_classes, :friendly_name, :decrees, :skip_finalize,
                                  :requires_assignment, :max_assignable)
  end
end
