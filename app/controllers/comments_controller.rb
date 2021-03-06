require "thread"

class CommentsController < ApplicationController
  before_action :set_comment, only: [:show, :edit, :update, :destroy]
  skip_before_action :authentication, only: [:create]

  # GET /comments
  # GET /comments.json
  def index
    @comments = Comment.all
  end

  # GET /comments/1
  # GET /comments/1.json
  def show
  end

  # GET /comments/new
  def new
    @comment = Comment.new
  end

  # GET /comments/1/edit
  def edit
  end

  # POST /comments
  # POST /comments.json
  def create
    @comment = Comment.new(comment_params)
    respond_to do |format|
      if @comment.save
        ####
        # 这里需要注意参数formats，layout，locals
        ###
        @html = render_to_string '_comment', formats: [:html], layout: false, locals: { comment: @comment }
        format.html { redirect_to @comment.post, notice: 'Comment was successfully created.' }
        format.json { render :show, status: :created, location: @comment }

        Thread.new do
          CommentNotifier.notify_author(@comment, @comment.post.author).deliver_later
          notify_mentioned_commentor
        end
      else
        format.html { redirect_to @comment.post, notice: "Cannot save comment." }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /comments/1
  # PATCH/PUT /comments/1.json
  def update
    respond_to do |format|
      if @comment.update(comment_params)
        format.html { redirect_to @comment, notice: 'Comment was successfully updated.' }
        format.json { render :show, status: :ok, location: @comment }
      else
        format.html { render :edit }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  def destroy
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to comments_url, notice: 'Comment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_comment
      @comment = Comment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def comment_params
      params.permit(:email, :content, :name, :post_id)
    end

    def notify_mentioned_commentor
      metioned_commmentors_names = @comment.content.scan(/(?<=@)[_\w\d]{2,31}(?=\s|\z)/i).uniq
      if metioned_commmentors_names.size.zero?
        return
      end

      comments = Comment.group(:email).where(:name => metioned_commmentors_names)
      comments.each do |comment|
        CommentNotifier.notify_commentor(comment, comment.post.author, @comment).deliver_later
      end
    end
end
