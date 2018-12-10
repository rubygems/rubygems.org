class Mailer < ActionMailer::Base
  include Roadie::Rails::Automatic

  default_url_options[:host] = Gemcutter::HOST
  default_url_options[:protocol] = Gemcutter::PROTOCOL

  def email_reset(user)
    @user = User.find(user['id'])
    mail from: Clearance.configuration.mailer_sender,
         to: @user.unconfirmed_email,
         subject: I18n.t('mailer.confirmation_subject',
           default: 'Please confirm your email address with RubyGems.org')
  end

  def email_confirmation(user)
    @user = User.find(user['id'])
    mail from: Clearance.configuration.mailer_sender,
         to: @user.email,
         subject: I18n.t('mailer.confirmation_subject',
           default: 'Please confirm your email address with RubyGems.org')
  end

  def deletion_complete(email)
    mail from: Clearance.configuration.mailer_sender,
         to: email,
         subject: I18n.t('mailer.deletion_complete.subject')
  end

  def deletion_failed(email)
    mail from: Clearance.configuration.mailer_sender,
         to: email,
         subject: I18n.t('mailer.deletion_failed.subject')
  end

  def adoption_requested(adoption_request)
    adoption_request = AdoptionRequest.find(adoption_request['id'])
    adoption_request.rubygem.owners.each do |owner|
      mail from: Clearance.configuration.mailer_sender,
           to: owner.email,
           subject: I18n.t('mailer.adoption_requested.subject', gem: adoption_request.rubygem.name) do |format|
        format.html { render locals: { adoption_request: adoption_request, owner: owner } }
      end
    end
  end

  def adoption_request_canceled(rubygem, user)
    user = User.find(user['id'])
    rubygem = Rubygem.find(rubygem['id'])

    mail from: Clearance.configuration.mailer_sender,
         to: user.email,
         subject: I18n.t('mailer.adoption_request_canceled.subject', gem: rubygem.name) do |format|
      format.html { render locals: { rubygem: rubygem, user: user } }
    end
  end

  def adoption_request_approved(rubygem, user)
    user = User.find(user['id'])
    rubygem = Rubygem.find(rubygem['id'])

    mail from: Clearance.configuration.mailer_sender,
         to: user.email,
         subject: I18n.t('mailer.adoption_request_approved.subject', gem: rubygem.name) do |format|
      format.html { render locals: { rubygem: rubygem, user: user } }
    end
  end
end
