# 手順

## 楽天APIの利用登録
アプリURLは一旦ngrokのURLを登録
herokuへデプロイ時にURL変える

## 取得したアプリIDを環境変数に登録
`.env`

```diff
LINE_CHANNEL_SECRET='xxxxxx'
LINE_CHANNEL_TOKEN='xxxxxx'
+ RAKUTEN_APPID='xxxxxx'
```

## HTTPClientのインストール
ネットワーク通信を取り扱うライブラリで、Rubyが標準で取り込んでいる同様のライブラリ`net/http` よりも取り扱いやすいライブラリとなっています。

Gemfileに以下を追記

```diff
・
・
・
gem 'dotenv-rails'

+ gem 'httpclient'
```

```
$ bundle install
```

```
・
・
・
Fetching httpclient 2.8.3
Installing httpclient 2.8.3
・
・
・
Bundle complete! 16 Gemfile dependencies, 67 gems now installed.
Bundled gems are installed into `./vendor/bundle`
```

## APIリクエストの準備

```diff
class LineBotController < ApplicationController
  ・
  ・
  ・
  private
    ・
    ・
    ・
+    def search_and_create_message(keyword)
+      url = 'https://app.rakuten.co.jp/services/api/Travel/KeywordHotelSearch/20170426'
+      client = HTTPClient.new
+      query = { 
+        'keyword' => keyword,
+        'applicationId' => ENV['RAKUTEN_APPID'],
+        'responseType' => 'small',
+        'hits' => 5,
+        'formatVersion' => 2
+      }
+    end
end
```

```
def search_and_create_message(keyword)
```
引数としてユーザーから送信されたテキストを受け取り、これをキーワードに宿泊検索をします。

```
url = 'https://app.rakuten.co.jp/services/api/Travel/KeywordHotelSearch/20170426'
```

楽天トラベルキーワード検索APIにリクエストするためのURLを`url`に代入しています。

```
client = HTTPClient.new
```

`HTTPClient`クラスを生成(インスタンス化)し、`client`に代入しています。

この`client`で`get`メソッドを使うと、指定したURLに対してGETリクエストを行い、そのレスポンスが返ってきます。

```
query = {
  'keyword' => keyword,
  'hits' => 5,
  'responseType' => 'small',
  'formatVersion' => 2,
  'applicationId' => ENV['RAKUTEN_APPID']
}
```

リクエストパラメーターとは

検索キーワードなど、サーバーに送信したいデータをURLの末尾に特定の形式で表記したもの

URLの末尾に「?」（クエスチョンマーク）を付け、続けて「名前=値」の形式で内容を記述する。値が複数あるときは「&」（アンパサンド）で区切り、「?名前1=値1&名前2=値2&名前3=値3」のように続ける

ここでは`keyword`、`hits`、`responseType`、`formatVersion`、`applicationId`をリクエストパラメータとして指定しています。

|パラメーター|意味|今回設定する値|
|--|--|--|
|keyword| 検索キーワード  |{ユーザーから送信されたテキスト}|
| hits  | 取得件数  |5|
| responseType  | 取得する情報量の度合い  |small(施設情報のみ)|
|formatVersion   | 出力フォーマットのバージョン指定 |2(詳細は下記リンク参照)|
|applicationId   | APIを利用するためのID  |{API利用登録で取得した値}|

詳細は以下の「入力パラメーター」の項で確認できます。

[楽天ウェブサービス: 楽天トラベルキーワード検索API(version:2017-04-26) | API一覧](https://webservice.rakuten.co.jp/api/keywordhotelsearch/)

## リクエスト

```diff
class LineBotController < ApplicationController
  ・
  ・
  ・
  private
    ・
    ・
    ・
    def search_and_create_message(keyword)
      url = 'https://app.rakuten.co.jp/services/api/Travel/KeywordHotelSearch/20170426'
      client = HTTPClient.new
      query = { 
        'keyword' => keyword,
        'applicationId' => ENV['RAKUTEN_APPID'],
        'responseType' => 'small',
        'hits' => 5,
        'formatVersion' => 2
      }
+      response = client.get(url, query)
+      response = JSON.parse(response.body)
    end
end
```

```
response = client.get(url, query)
```

`get`メソッドの第一引数には、リクエスト先のURLを渡します。

第二引数には、リクエストパラメータとなる情報をハッシュで渡します。

APIへのGETリクエストに対するレスポンスを`response`に代入しています。

```
response = JSON.parse(response.body)
```

レスポンスは以下の要素で成り立っています。

1. ステータスライン
1. レスポンスヘッダ
1. レスポンスボディ

このうち、リクエストした側が必要な情報(今回は宿泊施設の情報)はレスポンスボディにあります。

レスポンスボディに関しては、以下の記事がわかりやすいので参考にしてみてください。

[HTTPレスポンスボディとは](https://wa3.i-3-i.info/word1848.html)

`body`メソッドを利用することで、レスポンスボディにアクセスすることができます。

レスポンスは以下のようなJSONという形式の文字列となっています。

```
{
  "pagingInfo":
  {
    "recordCount":894,
    ・
    ・
    ・
  },
  "hotels":
  [
    [
      {
        "hotelBasicInfo":
        {
          "hotelNo":147784,
          "hotelName":"東急ステイ新宿",
          ・
          ・
          ・
        }
      }
    ],
    [
      {
        "hotelBasicInfo":
          {
            "hotelNo":658,
            "hotelName":"新宿ワシントンホテル　本館",
            ・
            ・
            ・
          }
      }
    ]
  ]
}
```

これをRubyで取り扱いやすくするため、`JSON.parse`メソッドを使って、ハッシュに変換しています。

変換後のレスポンスを`response`に再代入しています。

```
text = ''
response['hotels'].each do |hotel|
  text <<
    hotel[0]['hotelBasicInfo']['hotelName'] + "\n" +
    hotel[0]['hotelBasicInfo']['hotelInformationUrl'] + "\n" +
    "\n"
end
```

## メッセージの作成

今回作成したいメッセージのイメージは以下のようになります。

```
ホテル名1
ホテル情報ページURL1

ホテル名2
ホテル情報ページURL2

・
・
・
```

`response`は、わかりやすく今回の実装で関係する部分だけを抜粋すると、以下のような構造になっています。

```
{
  "hotels" => [
    [
      {
        "hotelBasicInfo" => {
          "hotelName" => "東急ステイ新宿",
          "hotelInformationUrl" => "https://xxxxx",
        }
      }
    ],
    [
      {
        "hotelBasicInfo" => {
          "hotelName" => "新宿ワシントンホテル　本館",
          "hotelInformationUrl" => "https://xxxxx",
        }
      }
    ],
    ・
    ・
    ・
  ]
}
```

`hotels`キーにそれぞれのホテル情報が配列で入っています。

配列の1つ目の要素に`hotelBasicInfo`というキーをもつハッシュがあり、ホテルの詳細情報が格納されています。

ホテル名は`hotelName`、ホテル情報ページURLは`hotelInformationUrl`というキーが割り振られています。

まとめると1つ目のホテルの名前には、以下のコードでアクセスできます。

```
response["hotels"][0][0]["hotelBasicInfo"]["hotelName"]
```

2つ目のホテルの名前には、以下のコードでアクセスできます。

```
response["hotels"][1][0]["hotelBasicInfo"]["hotelName"]
```

つまり`response["hotels"]`を`each`メソッドでループさせると、各ホテルの詳細情報に効率よくアクセスすることができることがわかります。

```diff
class LineBotController < ApplicationController
  ・
  ・
  ・
  private
    ・
    ・
    ・
    def search_and_create_message(keyword)
      url = 'https://app.rakuten.co.jp/services/api/Travel/KeywordHotelSearch/20170426'
      client = HTTPClient.new
      query = { 
        'keyword' => keyword,
        'applicationId' => ENV['RAKUTEN_APPID'],
        'responseType' => 'small',
        'hits' => 5,
        'formatVersion' => 2
      }
      response = client.get(url, query)
      response = JSON.parse(response.body)
+
+      text = ''
+      response['hotels'].each do |hotel|
+        text <<
+          hotel[0]['hotelBasicInfo']['hotelName'] + "\n" +
+          hotel[0]['hotelBasicInfo']['hotelInformationUrl'] + "\n" +
+          "\n"
+      end
    end
end
```

String型の変数`text`を宣言します。

`hotelName`と`hotelInformationUrl`の値を取り出し、文字列結合をおこなう`+`を使って結合させています。

"\n"は改行です(なお、Rubyでは、'\n'のようにシングルクォーテーションで囲むと改行と認識されないので注意してください)。

以下の文字列を作成しました。

```
ホテル名1
ホテル情報ページURL1

```

作成した文字列は`text`へ代入しますが、`<<`を利用することで、文字列を連結しています。

`each`でループするたびに以下のように文字列が連結していきます。

```
ホテル名1
ホテル情報ページURL1

ホテル名2
ホテル情報ページURL2

・
・
・
```

すべて連結し終わったら、返信内容のタイプとテキストを保持したハッシュを作成します。

```
message = {
  type: 'text',
  text: text
}
```

`type`キーに`'text'`、`text`キーに送信されたメッセージそのものを示す`event.message['text']`を指定したハッシュを宣言し`message`変数に代入します。

## メソッド呼び出す

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
-          message = {
-            type: 'text',
-            text: event.message['text']
-          }
+          message = search_and_create_message(event.message['text'])
          client.reply_message(event['replyToken'], message)
        end
      end
    end
    head :ok
  end
  ・
  ・
  ・
end
```

オウム返し部分を削除

`search_and_create_message`メソッドにユーザーから送信されたメッセージである`event.message['text']`を渡してあげる

返り値は返信内容のタイプとテキストを保持したハッシュなので、それを`client.reply_message`メソッドの第二引数にそのまま渡してあげれば良い

## エラー処理

検索キーワードに該当するホテルがなかった場合に返答するようにしよう

```diff
class LineBotController < ApplicationController
  ・
  ・
  ・
  private
    ・
    ・
    ・
    def search_and_create_message(keyword)
      ・
      ・
      ・
      response = client.get(url, query)
      response = JSON.parse(response.body)

+      if response.key?('error')
+        text = "この検索条件に該当する宿泊施設が見つかりませんでした。\n条件を変えて再検索してください。"
+      else
        text = ''
        response['hotels'].each do |hotel|
          text <<
            hotel[0]['hotelBasicInfo']['hotelName'] + "\n" +
            hotel[0]['hotelBasicInfo']['hotelInformationUrl'] + "\n" +
            "\n"
        end
+      end

      message = {
        type: 'text',
        text: text
      }
    end
end
```

検索キーワードに該当するホテルがなかった場合、以下のレスポンスが返ってくる。
```
{
  "error": "not_found",
  "error_description": "Data Not Found"
}
```

`key?`メソッドは指定したキー名が存在した場合に`true`を返します。

今回は`error`というキーが存在した場合に`text`に`この検索条件に該当する宿泊施設が見つかりませんでした。\n条件を変えて再検索してください。`というメッセージを代入しています。
