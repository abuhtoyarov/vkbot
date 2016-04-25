require './lib/database_connector'

class AppConfigurator

  def configure
    setup_i18n
    setup_database
  end

  def get_bot_token
    YAML::load(IO.read('config/secrets.yml'))['telegram_bot_token']
  end

  def get_inst_client_id
    YAML::load(IO.read('config/secrets.yml'))['client_id']
  end

  def get_inst_client_secret
    YAML::load(IO.read('config/secrets.yml'))['client_secret']
  end

  private

  def setup_i18n
    I18n.load_path = Dir['config/locales.yml']
    I18n.locale = :en
    I18n.backend.load_translations
  end

  def setup_database
    DatabaseConnector.establish_connection
  end
end
