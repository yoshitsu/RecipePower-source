class TagsetsController < ApplicationController
  before_action :set_tagset, only: [:show, :edit, :update, :destroy]

  # GET /tagsets
  def index
    @tagsets = Tagset.all
  end

  # GET /tagsets/1
  def show
  end

  # GET /tagsets/new
  def new
    # @tagset = Tagset.new
    update_and_decorate Tagset.new
    # @tagset.tagging_user_id = current_user.id
  end

  # GET /tagsets/1/edit
  def edit
  end

  # POST /tagsets
  def create
    @tagset = Tagset.create
    @tagset.uid = current_user.id
    @tagset.update_attributes tagset_params
    if update_and_decorate @tagset
      redirect_to @tagset, notice: 'Tagset was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /tagsets/1
  def update
    if update_and_decorate # @tagset.update(tagset_params)
      redirect_to @tagset, notice: 'Tagset was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /tagsets/1
  def destroy
    @tagset.destroy
    redirect_to tagsets_url, notice: 'Tagset was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tagset
      @tagset = Tagset.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def tagset_params
      params[:tagset]
    end
end