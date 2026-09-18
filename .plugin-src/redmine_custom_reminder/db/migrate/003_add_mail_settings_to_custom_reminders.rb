class AddMailSettingsToCustomReminders < ActiveRecord::Migration[5.2]
  DEFAULT_SUBJECT = '[{{project}}][#{{issue_id}}]'
  DEFAULT_BODY = <<~BODY
    [Overdue Ticket Reminder]

    The ticket assigned to you has exceeded its target due date. Please log in to Redmine as soon as possible to review, update the ticket status, and complete the required actions.

    Thank you for your cooperation.
  BODY

  def change
    add_column :custom_reminders, :scheduled_time, :string, limit: 5, null: false, default: '09:00'
    add_column :custom_reminders, :mail_subject_template, :string, limit: 255, null: false, default: DEFAULT_SUBJECT
    add_column :custom_reminders, :mail_body_template, :text

    reversible do |dir|
      dir.up do
        CustomReminder.update_all(mail_body_template: DEFAULT_BODY)
        change_column_null :custom_reminders, :mail_body_template, false
      end
    end
  end
end
