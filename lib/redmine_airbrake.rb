module RedmineAirbrake

  def self.rails5?
    Gem::Version.new(Rails.version) >= Gem::Version.new('5.0.0')
  end
end
