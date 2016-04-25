require './models/user'
require './lib/message_sender'

class MessageResponder
  attr_reader :message
  attr_reader :bot
  attr_reader :user

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @user = User.find_or_create_by(uid: message.from.id)
    @authorize_url = options[:authorize_url]

    @kb = [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Send audio or photos to freinds.', switch_inline_query: 'song ' )]
  end

  def respond
    on /^\/start$/ do
      answer_with_greeting_message
    end

    on /^\/stop/ do
      answer_with_farewell_message
    end

    on /\/auth$/ do
      answer_auth
    end

    on /^\/logout$/ do
      answer_logout
    end

    on /\/captcha$/ do
      answer_captcha
    end

    on /^\/setcaptcha/ do
      key = message.text.split(' ').last
      set_captcha(key)
    end

    on /^\/start code_/ do
      answer_get_token(message.text.split('_').last)
    end
  end

  private

  def on regex, &block
    regex =~ message.text

    if $~
      case block.arity
      when 0
        yield
      when 1
        yield $1
      when 2
        yield $1, $2
      end
    end
  end

  def answer_with_greeting_message
    text = I18n.t('greeting_message')
    answer_with_message(text, @kb)
  end

  def answer_captcha
    answer_with_message(user.captcha_img)
  end

  def set_captcha(key)
    begin
      client = VkontakteApi::Client.new(user.token)
      client.users.get(uid: 1, captcha_sid: user.captcha_sid, captcha_key: key)

      answer_with_message('Ok')
    rescue VkontakteApi::Error => e
      bot.logger.info(e.to_s)
    end
  end

  def answer_auth
    answer_with_message(@authorize_url)
  end

  def answer_logout
    return unless user
      user.token = nil
      if user.save
        answer_with_message('logout ok')
      end
  end

  def answer_get_token(code)
    bot.logger.info("Your code: #{code}")
    begin
    vk = VkontakteApi.authorize(code: code)
    bot.logger.info("Your token: #{vk}")
    user.token = vk.token
    user.save!

    MessageSender.new(bot: bot, chat: message.chat, text: "Hello, #{vk} ", answers: @kb).send

    rescue Exception => e
      bot.logger.info("Error #{e}")
    end
  end

  def answer_with_farewell_message
    text = I18n.t('farewell_message')

    answer_with_message(text)
  end

  def answer_with_message(text, answer=nil)
    MessageSender.new(bot: bot, chat: message.chat, text: text, answers: answer).send
  end
end
