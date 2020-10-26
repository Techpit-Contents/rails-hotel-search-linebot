# 手順書
## line-bot-apiインストール
gemファイルの最後尾に以下を記述
```
gem 'line-bot-api'
```

以下のコマンドを実行
```
bundle install
```

数行表示されたあとに`Bundle complete!・・・`と表示されていれば成功

```
・
・
・
Fetching line-bot-api 1.16.0
Installing line-bot-api 1.16.0
・
・
・
Bundle complete! 14 Gemfile dependencies, 64 gems now installed.
Bundled gems are installed into `./vendor/bundle`
```

## lineBotコントローラ作成
rails generate controller LineBot

確認：App/controller/line_bot_controller 作成されていればOK

## callbackアクションの作成

以下を記載
```diff
class LinebotController < ApplicationController
+  def callback
+  end
end
```

## ルーティングを定義
以下を記載
```diff
Rails.application.routes.draw do
-  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
+  post '/callback' => 'linebot#callback'
end
```

## ngrokインストール
[laravelの教材参照](https://github.com/Techpit-Market/laravel-linebot/blob/master/curriculum/2%E7%AB%A0%EF%BC%9ALINE%20Messaging%20API%E3%81%A8%E9%80%A3%E6%90%BA%E3%81%97%E3%81%A6%E3%82%AA%E3%82%A6%E3%83%A0%E8%BF%94%E3%81%97Bot%E3%82%92%E4%BD%9C%E3%82%8D%E3%81%86/2-6%20%E9%96%8B%E7%99%BA%E7%92%B0%E5%A2%83%E3%81%AELaravel%E3%82%92%E4%B8%80%E6%99%82%E7%9A%84%E3%81%AB%E5%A4%96%E9%83%A8%E3%81%8B%E3%82%89%E9%80%9A%E4%BF%A1%E3%81%A7%E3%81%8D%E3%82%8B%E3%82%88%E3%81%86%E3%81%AB%E3%81%99%E3%82%8B.md)

ngrokで公開してアクセスしてrailsの初期画面表示


## 環境変数の設定
### gem 'dotenv-rails' のインストール
`Gemfile`に以下記載
```
gem 'dotenv-rails'
```

```
$ bundle install
```

```
・
・
・
Fetching dotenv 2.7.6
Installing dotenv 2.7.6
・
・
・
Fetching dotenv-rails 2.7.6
Installing dotenv-rails 2.7.6
・
・
・
Bundle complete! 15 Gemfile dependencies, 66 gems now installed.
Bundled gems are installed into `./vendor/bundle`
```

### .envファイルを作成
プロジェクトのルートディレクトリに作成
```
$ touch .env
```

### 環境変数を設定
作成した.envファイルに環境変数を記述します。

```
LINE_CHANNEL_SECRET='xxxxxxxx'
LINE_CHANNEL_TOKEN='xxxxxxxx'
```

### .gitignoreに.envを追加
最後尾に以下追加
```
/.env
```

### 認証情報を設定

LINE Messaging API SDKには、Botとして様々な処理を行うための、`Line::Bot::Client`クラスが用意されています。

> クラスの入れ子についてはRubyの範囲なので説明しない方向
https://qiita.com/noraworld/items/947f6725a4d617820265

`Line::Bot::Client`クラスをインスタンス化するために以下のコードを追加

```diff
class LineBotController < ApplicationController
+  private
+
+    def client
+      @client ||= Line::Bot::Client.new { |config|
+        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
+        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
+      }
+    end
end
```

`ENV["xxx"]`が使われていますが、これは.envファイルの中で指定した変数名の値が返ります(あるいはPCやサーバーに設定された環境変数の値が返ります)。

2-4 アクセストークンの設定では、.envファイルに`LINE_CHANNEL_SECRET`と`LINE_CHANNEL_TOKEN`を設定しました。その値が返るというわけです。

それ以外の追加コードに関しては「LINEBotクラスを生成するにはこのような手順となっているんだ」ぐらいに思ってもらえれば大丈夫です。

## セキュリティの無効化
### CSRF対策無効化

`line_bot_controller.rb`

```diff
class LineBotController < ApplicationController
+  protect_from_forgery except: [:callback]
+
  private
  ・
  ・
  ・
end
```

### ホスト名をホワイトリストに登録

Rails6ではDNS Rebuilding攻撃を防ぐためにホスト名をホワイトリストに登録しなければならない。

今回は便宜上、全てのホスト名でアクセス可能の設定をする。

`development.rb`

最後尾に以下追加

```
Rails.application.configure do
・
・
・
+  config.hosts.clear
end
```

## POSTリクエストの確認

`line_bot_controller.rb`

```
class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

+  def callback
+  end

  ・
  ・
  ・
end
```

rails server を立ち上げているターミナルを確認するとLINEチャネルからのPOSTリクエストが確認できる。

```
Parameters: {"events"=>[{"type"=>"message", "replyToken"=>"xxx", "source"=>{"userId"=>"xxx", "type"=>"user"}, "timestamp"=>1603537341048, "mode"=>"active", "message"=>{"type"=>"text", "id"=>"xxx", "text"=>"テスト"}}], "destination"=>"xxx", "line_bot"=>{"events"=>[{"type"=>"message", "replyToken"=>"xxx", "source"=>{"userId"=>"xxx", "type"=>"user"}, "timestamp"=>1603537341048, "mode"=>"active", "message"=>{"type"=>"text", "id"=>"xxx", "text"=>"テスト"}}], "destination"=>"xxx"}}
```

## メッセージボディを取得

`line_bot_controller.rb`

```diff
class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
+    body = request.body.read
+    p body
  end

  ・
  ・
  ・
end
```

POSTリクエストは`request`に渡ってくる。

リクエストを構成する要素に、ヘッダーとメッセージボディというものがありますが、`request.body`はメッセージボディ、`request.env`にはヘッダーが返される。

rails server を立ち上げているターミナルを確認するとPOSTリクエストからメッセージボディを文字列として取得できていることがわかる。

```
"{\"events\":[{\"type\":\"message\",\"replyToken\":\"xxx\",\"source\":{\"userId\":\"xxx\",\"type\":\"user\"},\"timestamp\":1603539210962,\"mode\":\"active\",\"message\":{\"type\":\"text\",\"id\":\"xxx\",\"text\":\"んん\"}}],\"destination\":\"xxx\"}"
"xxxf"
```

## 署名の検証をおこなう

LINEチャネルのような外部APIとの通信において、セキュリティ的に気をつけておくべき事項の中に以下の2点が挙げられます。

他人が作ったLINEチャネルや、LINEチャネルを装った全く別のサーバーと通信してしまうリスク

あなたのLINEチャネルからのリクエストの中身が、Laravelに届くまでの間に第三者に改ざんされてしまうリスク

LINEチャネルからのリクエストには署名(signature)の情報が含まれており、これを検証することで上記のリスクへの対策となります。

署名を検証する機能はSDKに用意されているので、これを利用しましょう。

`line_bot_controller.rb`

```diff
class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    body = request.body.read
-    p body
+    signature = request.env['HTTP_X_LINE_SIGNATURE']
+    unless client.validate_signature(body, signature)
+      error 400 do 'Bad Request' end
+    end
  end

  ・
  ・
  ・
end

```

```
signature = request.env['HTTP_X_LINE_SIGNATURE']
```

リクエストのヘッダーである`request.env`の'HTTP_X_LINE_SIGNATURE'をキーとする値を`signature`に代入している。

```
unless client.validate_signature(body, signature)
  return head :bad_request
end
```

`validate_signature`メソッドは、メッセージボディと署名を引数として受け取り、署名の検証を行います。

メッセージボディは文字列で渡す必要があるため、`request.body.read`として文字列で取得していた。

次に署名の検証についてです。

署名の検証には鍵情報(LINE_CHANNEL_SECRET)も必要ですが、引数として渡してはいません。

これはメソッドの呼び出し元の`client`が既にその情報を持っており、メソッド内部でそれが使われているためとなります。

署名の検証結果はtrueかfalseで返ります。

`head`メソッドはステータスコードを返したいときに使う。

`:bad_request`を指定すると`400`が返される。

ステータスコードについては以下参照

[HTTP レスポンスステータスコード - HTTP | MDN](https://developer.mozilla.org/ja/docs/Web/HTTP/Status)


LINE側が送ってきたメッセージが正しいか検証するための署名参考

[メッセージ（Webhook）を受信する | LINE Developers](https://developers.line.biz/ja/docs/messaging-api/receiving-messages/#verifying-signatures)

## LINEのチャネルに返信する

### メッセージボディを配列で取得

`line_bot_controller.rb`

```diff
class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
+    events = client.parse_events_from(body)
  end

  ・
  ・
  ・
end
```

`parse_events_from`メソッドに文字列として取得していたメッセージボディである`body`を引数として渡すと、配列に変換して返してくれる。

### メッセージボディの解析

まずはメッセージボディから送信されてきたテキストを取り出すため、解析をおこないます。

`line_bot_controller.rb`

```diff
class LineBotController < ApplicationController

  protect_from_forgery except: [:callback]

  def callback
    ・
    ・
    ・
    events = client.parse_events_from(body)
+    events.each do |event|
+      case event
+      when Line::Bot::Event::Message
+        case event.type
+        when Line::Bot::Event::MessageType::Text
+        end
+      end
+    end
  end

  ・
  ・
  ・
end
```

```
events.each do |event|
・
・
・
end
```

メッセージボディを配列にした`events`変数を`each`メソッドを用いてループさせ、各要素を`event`変数として扱います。

```
  case event
  when Line::Bot::Event::Message
    ・
    ・
    ・
  end
```

`case`文を用いて`event`が`Line::Bot::Event::Message`クラスかどうか、つまりユーザーがメッセージを送信したことを示すイベント(メッセージイベント)かどうかを確認します。

他のイベントで例を上げると、LINE Botがメンバーになっているグループやトークルームにユーザーが参加したことを示すイベントなどがあります。

詳しくは下記を参照してください。

[メッセージ（Webhook）を受信する | LINE Developers](https://developers.line.biz/ja/docs/messaging-api/receiving-messages/#webhook-event-types)


```
    case event.type
    when Line::Bot::Event::MessageType::Text
    end
```

次に`event`の`type`プロパティが`Line::Bot::Event::MessageType::Text`クラスかどうか、つまりメッセージがテキストかどうかを確認します。

テキスト以外では、例えばスタンプの場合は`sticker`、画像の場合は`image`となります。

詳しくは下記を参照してください。

[Messaging APIリファレンス | LINE Developers](https://developers.line.biz/ja/reference/messaging-api/#message-event)

ここまででメッセージボディの解析が完了し、送られてきたメッセージがテキストであることが確認できました。

### 返信メッセージの作成

続いて、返信メッセージを作成します。

返信メッセージは送信されてきたメッセージと同様にメッセージタイプとテキストをハッシュで作成します。

`line_bot_controller.rb`

```diff
class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    ・
    ・
    ・
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
+          message = {
+            type: 'text',
+            text: event.message['text']
+          }
        end
      end
    end
  end
  ・
  ・
  ・
end
```

`type`キーに`'text'`、`text`キーに送信されたメッセージそのものを示す`event.message['text']`を指定したハッシュを宣言し`message`変数に代入しました。

### 返信する

```diff
class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    ・
    ・
    ・
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: event.message['text']
          }
        end
      end
  +    client.reply_message(event['replyToken'], message)
    end
  +  head :ok
  end
  ・
  ・
  ・
end
```

```
client.reply_message(event['replyToken'], message)
```

LINE Messaging APIでは、各メッセージに応答トークンを割り振っており、そのメッセージへの返信にこの応答トークンを必要とします。

- [Messaging APIリファレンス | LINE Developers](https://developers.line.biz/ja/reference/messaging-api/#send-reply-message)

応答トークンは`event`の`replyToken`キーを参照することで取得できます。

`reply_message`メソッドの第一引数に応答トークン、第二引数に先程宣言した`message`、つまり返信内容のタイプとテキストを保持したハッシュを渡すと、テキストメッセージでの返信が行われます。

```
head :ok
```

最後にステータスコードとして正常を示す`200`を表す`:ok`を指定して完了です。