class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      return head :bad_request
    end
    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = search_and_create_message(event.message['text'])
          client.reply_message(event['replyToken'], message)
        end
      end
    end
    head :ok
  end

  private

    def client
      @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV['LINE_CHANNEL_SECRET']
        config.channel_token = ENV['LINE_CHANNEL_TOKEN']
      }
    end

    def search_and_create_message(keyword)
      http_client = HTTPClient.new
      url = 'https://app.rakuten.co.jp/services/api/Travel/KeywordHotelSearch/20170426'
      query = { 
        'keyword' => keyword,
        'applicationId' => ENV['RAKUTEN_APPID'],
        'hits' => 5,
        'responseType' => 'small',
        'formatVersion' => 2
      }
      response = http_client.get(url, query)
      response = JSON.parse(response.body)

      if response.key?('error')
        text = "この検索条件に該当する宿泊施設が見つかりませんでした。\n条件を変えて再検索してください。"
      else
        text = ''
        response['hotels'].each do |hotel|
          text <<
            hotel[0]['hotelBasicInfo']['hotelName'] + "\n" +
            hotel[0]['hotelBasicInfo']['hotelInformationUrl'] + "\n" +
            "\n"
        end
      end

      message = {
        type: 'text',
        text: text
      }
    end
end
