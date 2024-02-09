class Events::TableComponentPreview < Lookbook::Preview
  def default
    events = [
      FactoryBot.build(:events_user_event, created_at: Time.current),
      FactoryBot.build(:events_rubygem_event, created_at: Time.current)
    ]
    render Events::TableComponent.new(security_events: page(events))
  end

  def empty
    render Events::TableComponent.new(security_events: page([]))
  end

  private

  def page(array, page: 0, per: 10)
    Kaminari.paginate_array(array).page(page).per(per)
  end
end
