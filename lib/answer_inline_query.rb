class AnswerInlineQuery

    attr_reader :bot
    attr_reader :token
    attr_reader :query
    attr_reader :query_id

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
    bot.api.answer_inline_query(inline_query_id: query_id, results: results,
                                cache_time: 1, switch_pm_text: @pm_text,
                                switch_pm_parameter: @pm_param)
  end

  private

  def results
    if token.present?
      fill_result
    else
      @pm_text, @pm_param = ['Sign in to Instagram', '/auth']
    end
  end

  def fill_result
    result = []
    client

    on /^song./ do
      q = query.split('song ').last

      if !q.nil?
        songs = @vk.audio.search(q: q, count: 10)
        songs.shift

        songs.each_with_index do |song, index|
          result << Telegram::Bot::Types::InlineQueryResultAudio.new(
            id: index,
            audio_url: song.url,
            title: song.title,
            audio_duration: song.duration
          )
        end
      end
    end
    result
  end

  private

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
