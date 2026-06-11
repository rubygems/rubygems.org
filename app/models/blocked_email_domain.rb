# frozen_string_literal: true

class BlockedEmailDomain < ApplicationRecord
  include EmailDomainNormalization

  has_many :audits, as: :auditable, dependent: :nullify

  enum :source, { manual: 0, upstream: 1 }

  PROTECTED_PROVIDERS = %w[
    gmail.com googlemail.com
    outlook.com hotmail.com live.com msn.com
    yahoo.com yahoo.co.uk yahoo.co.jp yahoo.de yahoo.fr ymail.com
    icloud.com me.com mac.com
    proton.me protonmail.com pm.me
    aol.com
    fastmail.com
    zoho.com
    qq.com 163.com 126.com sina.com sina.cn
    yandex.ru yandex.com
    mail.ru bk.ru list.ru inbox.ru
    gmx.com gmx.de gmx.net gmx.at gmx.ch
    web.de t-online.de
    mail.com
    tuta.com tutanota.com tutamail.com tuta.io
    naver.com daum.net hanmail.net
    rediffmail.com
  ].freeze

  validates :domain, exclusion: { in: PROTECTED_PROVIDERS, message: :protected_provider }
  validates :notes, length: { maximum: 500 }, allow_blank: true

  scope :matching_email, ->(email) { where(domain: candidate_domains(email)) }

  def self.match(email_or_domain)
    candidates = candidate_domains(email_or_domain)
    return nil if candidates.empty?
    return nil if EmailDomainAllowlist.exists?(domain: candidates)
    most_specific_match(candidates)
  end

  def self.blocks?(email_or_domain)
    !match(email_or_domain).nil?
  end

  def self.most_specific_match(candidates)
    where(domain: candidates).max_by { |r| r.domain.length }
  end
end
