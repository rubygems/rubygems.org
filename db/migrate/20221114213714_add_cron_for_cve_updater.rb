class AddCronForCveUpdater < ActiveRecord::Migration[7.0]
  def up
    # every day at 3am
    Delayed::Job.enqueue(CveUpdater.new, cron: '0 3 * * *')
  end

  def down
    Delayed::Job
      .where('handler LIKE ?', "%ruby/object:CveUpdater%")
      .first.delete
  end
end
