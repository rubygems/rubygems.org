# frozen_string_literal: true

class Organizations::GemNameReservationsController < Organizations::BaseController
  PER_PAGE = 50

  before_action :set_page, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :render_not_found

  def index
    authorize @organization, :list_gem_name_reservations?

    reservations = @organization.gem_name_reservations.order(:name)
    @gem_name_reservations_count = reservations.count
    @gem_name_reservations = reservations.page(@page).per(PER_PAGE)
  end

  def new
    @gem_name_reservation = @organization.gem_name_reservations.build
    authorize @gem_name_reservation, :new?
  end

  def create
    @gem_name_reservation = @organization.gem_name_reservations.build(gem_name_reservation_params)
    authorize @gem_name_reservation, :create?

    if @gem_name_reservation.save
      redirect_to organization_gem_name_reservations_path(@organization), notice: t(".gem_name_reserved")
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @gem_name_reservation = @organization.gem_name_reservations.find(params.expect(:id))
    authorize @gem_name_reservation, :destroy?

    @gem_name_reservation.destroy!

    redirect_to organization_gem_name_reservations_path(@organization), notice: t(".gem_name_reservation_removed")
  end

  private

  def find_organization
    @organization = Organization.find_by_handle!(params[:organization_id])
  end

  def gem_name_reservation_params
    params.expect(gem_name_reservation: [:name])
  end
end
