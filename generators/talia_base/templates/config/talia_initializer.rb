TaliaCore::Initializer.environment = ENV['RAILS_ENV']
TaliaCore::Initializer.run("talia_core")

TaliaCore::SITE_NAME = TaliaCore::CONFIG['site_name'] || 'Discovery Source'