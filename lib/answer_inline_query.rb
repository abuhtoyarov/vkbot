class AnswerInlineQuery

    attr_reader :bot
    attr_reader :token
    attr_reader :query
    attr_reader :query_id
    attr_reader :user

  def initialize(id, query, bot, user)
    @query_id = id
    @query = query
    @bot = bot
    @user = User.find_by_uid(user.id)
    @token = @user.try(:token)
    @params = {}
    @vk = nil
  end

  def send

    begin
      bot.api.answer_inline_query(inline_query_id: query_id, results: results,
                                  cache_time: 1, switch_pm_text: @pm_text,
                                  switch_pm_parameter: @pm_param)
    rescue Exception => e
      bot.logger.info("Send error: #{e}")
    end
  end

  private

  def results
    if token.present?
      fill_result
    else
      @pm_text, @pm_param = ['Sign in to VK', '/auth']
    end
  end

def fill_result
    result = []
    client

    on /^song./ do
      q = query.split('song ').last

      if !q.nil?
        begin
          songs = @vk.audio.search(q: q, sort: 2, auto_complete: 1)
          songs.shift

          songs.each_with_index do |song, index|
            result << Telegram::Bot::Types::InlineQueryResultAudio.new(
              id: index,
              audio_url: song.url,
              title: song.title,
              performer: song.artist,
              audio_duration: song.duration
            )
          end

        rescue VkontakteApi::Error => e
          if e.error_code == 14
            bot.logger.info("Captcha needed")
            @pm_text, @pm_param = ['Captcha needed', '/captcha']
            user.update(captcha_img: e.captcha_img, captcha_sid: e.captcha_sid)
          end
        end
      end
    end

    on /^video./ do
      q = query.split('video ').last

      if !q.nil?
        begin
          video = @vk.video.search(q: q, sort: 2)
          video.shift

          video.each_with_index do |v, index|
            result << Telegram::Bot::Types::InlineQueryResultVideo.new(
              id: index,
              video_url: v.player,
              mime_type: 'video',
              thumb_url: v.thumb,
              title: v.title,
              video_duration: v.duration,
              description:  v.description
            )
          end

        rescue VkontakteApi::Error => e
          bot.logger.info("VK Error: #{e.error_code}")
          if e.error_code == 14
            bot.logger.info("Captcha needed")
            @pm_text, @pm_param = ['Captcha needed', '/captcha']
            user.update(captcha_img: e.captcha_img, captcha_sid: e.captcha_sid)
          end
        end
      end
    end

    on /^myphotos/ do
      begin
        images = @vk.photos.getAll()
        images.shift

        images.each_with_index do |photo, index|
          result << Telegram::Bot::Types::InlineQueryResultPhoto.new(
            id: index,
            photo_url: photo.src_big,
            thumb_url: photo.src,
          )
        end
      rescue VkontakteApi::Error => e
        if e.error_code == 14
          bot.logger.info("Captcha needed")
          @pm_text, @pm_param = ['Captcha needed', '/captcha']
          user.update(captcha_img: e.captcha_img, captcha_sid: e.captcha_sid)
        end
      end
    end

    on /^myaudio$/ do
      begin
        songs = @vk.audio.get()
        songs.each_with_index do |song, index|
          result << Telegram::Bot::Types::InlineQueryResultAudio.new(
            id: index,
            audio_url: song.url,
            title: song.title,
            performer: song.artist,
            audio_duration: song.duration
          )
        end

      rescue VkontakteApi::Error => e
        if e.error_code == 14
          bot.logger.info("Captcha needed")
          @pm_text, @pm_param = ['Captcha needed', '/captcha']
          user.update(captcha_img: e.captcha_img, captcha_sid: e.captcha_sid)
        end
      end
    end

    result
  end


  def client
    @vk ||= VkontakteApi::Client.new(token)
  end

  def on regex, &block
    regex =~ query

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
end
