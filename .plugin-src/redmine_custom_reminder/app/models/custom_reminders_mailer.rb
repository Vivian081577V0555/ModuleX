class CustomRemindersMailer < Mailer
  layout 'mailer'

  def custom_reminder(user, issue, params = {})
    @issue = issue
    @custom_reminder = params[:custom_reminder]
    @issue_url = Rails.application.routes.url_helpers.issue_path(@issue)

    hostonly = Setting.host_name.gsub(/^https:\/\//,'') unless Setting.host_name.downcase.match("^http://")
    hostonly = Setting.host_name.gsub(/^http:\/\//,'') unless Setting.host_name.downcase.match("^https://")
    hostonly = hostonly.gsub(%r{#{Redmine::Utils.relative_url_root}},'')
    @issue_url = "#{Setting.protocol}://#{hostonly}#{@issue_url}"
    @mail_body = @custom_reminder.render_mail_body(@issue)

    mail to: user,
         subject: @custom_reminder.render_mail_subject(@issue)
  end

  def self.custom_reminders(issues_by_user = {}, projects = [], custom_reminder = nil)
    saved_method = ActionMailer::Base.delivery_method
    if m = saved_method.to_s.match(/^async_(.+)$/)
      synched_method = m[1]
      ActionMailer::Base.delivery_method = synched_method.to_sym
      ActionMailer::Base.send "#{synched_method}_settings=", ActionMailer::Base.send("async_#{synched_method}_settings")
    end
    issues_by_user.each do |assignee, issues|
      if assignee.is_a?(User) && assignee.active? && issues.present?
        visible_issues = issues.select { |i| i.visible?(assignee) }
        Rails.logger.info("CustomReminder ##{custom_reminder&.id} found no visible issues for #{assignee.login}") if visible_issues.empty?
        submitted_count = 0
        visible_issues.each do |issue|
          message = custom_reminder(assignee, issue, projects: projects, custom_reminder: custom_reminder)
          Rails.logger.info("CustomReminder ##{custom_reminder&.id} submitting email to=#{assignee.mail} issue=#{issue.id} subject=#{message.subject}")
          begin
            message.deliver
            submitted_count += 1
          rescue StandardError => e
            Rails.logger.error("CustomReminder ##{custom_reminder&.id} failed email to=#{assignee.mail} issue=#{issue.id}: #{e.class}: #{e.message}")
          end
        end
        Rails.logger.info("CustomReminder ##{custom_reminder&.id} submitted #{submitted_count} email(s) to #{assignee.login}") if submitted_count.positive?
      end
    end
  ensure
    ActionMailer::Base.delivery_method = saved_method
  end
end
