class CampaignsController < ApplicationController
  before_action :set_campaign, only: [:show, :edit, :update, :destroy, :groups, :admin]

  # GET /campaigns
  def index
    check_permission "admin"
    @campaigns = Campaign.all
  end

  # GET /campaigns/1
  def show
    @recent_updates = Entity.includes(last_user: { sf_guard_user: :sf_guard_user_profile })
                            .where(last_user_id: @campaign.sf_guard_user_ids)
                            .order("updated_at DESC").limit(10)

    @carousel_entities = @campaign.featured_entities.limit(20)
  end

  # GET /campaigns/new
  def new
    check_permission "admin"
    @campaign = Campaign.new
  end

  # GET /campaigns/1/edit
  def edit
    check_permission "admin"
  end

  # POST /campaigns
  def create
    @campaign = Campaign.new(campaign_params)
    add_logo
    add_cover

    if @campaign.save
      redirect_to @campaign, notice: 'Campaign was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /campaigns/1
  def update
    @campaign.assign_attributes(campaign_params)
    add_logo
    add_cover

    if @campaign.save
      redirect_to @campaign, notice: 'Campaign was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /campaigns/1
  def destroy
    @campaign.destroy
    redirect_to campaigns_url, notice: 'Campaign was successfully destroyed.'
  end

  def search_groups
    data = []
    groups = Group.search Riddle::Query.escape(params[:q]), per_page: 10, match_mode: :extended
    data = groups.collect { |g| { value: g.name, name: g.name, id: g.id, slug: g.slug } }
    render json: data    
  end

  def groups
    # @groups = @campaign.groups.working.order(:name).page(params[:page]).per(20)

    @groups = @campaign.groups
      .select("groups.*, COUNT(DISTINCT(group_users.user_id)) AS user_count")
      .joins(:group_users)
      .joins(:sf_guard_group)
      .group("groups.id")
      .where(is_private: false, sf_guard_group: { is_working: true })
      .having("user_count > 0")
      .order("groups.name")
      .page(params[:page]).per(20)
  end

  def admin
    check_permission "admin"
  end

  private
    def add_logo
      @campaign.logo = params[:campaign][:logo] unless params[:campaign][:logo].nil?
    end

    def add_cover
      @campaign.cover = params[:campaign][:cover] unless params[:campaign][:cover].nil?
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_campaign
      @campaign = Campaign.find_by_slug(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def campaign_params
      params.require(:campaign).permit(:name, :slug, :tagline, :description, :logo, :cover, :findings, :howto)
    end
end
