class Registration < ActiveRecord::Base

  validates :password, :presence => true
  validates :email, :presence => true

  validate :tumblr_login

  after_create :set_tumblelog

  def tumblelogs
    @tumblelogs ||= tumblr_handler.tumblelogs
  end

  def modify_tumblelogs_domain!
    DomainChanger.handler.new(self.tumblelog, self.email, self.password).change_to(self.domain)
  end

  private

  def tumblr_login
    unless tumblr_handler.authorized?
      self.errors.add(:base, 'Could not log in to Tumblr.  Please try again.')
    end
  end

  def tumblr_handler
    @tumblr_handler ||= TumblrApi.handler.new(self.email, self.password)
  end

  def set_tumblelog
    if tumblelogs.size == 1
      self.tumblelog = tumblelogs.first['name']
    end
  end
end
