# 手順
## Flex Messageについて
Flex Messageは複数の要素を組み合わせてレイアウトを自由にカスタマイズできるメッセージです。

Flex Messageは、コンテナ、ブロック、コンポーネントの3層のデータ構造から構成されます。

コンテナはバブルメッセージとカルーセルメッセージがあります。

- バブルメッセージ：1つのメッセージを表示
- カルーセルメッセージ：複数のバブルメッセージを表示

### Flex Messageの構築ツール

Flex Messageは自由度が高い分デザインが大変なのですが、Flex Message Simulatorというツールを使うと手軽に構築することができます。

[Flex Message Simulator](https://developers.line.biz/flex-simulator/)

シミュレーターは、以下の構成となっています。

左側にFlex Messageのレイアウト
右側にFlex Messageのデータ構造を参照・更新可能なユーザーインターフェース

次に画面右上のShowcaseボタンを押してください。

いくつかのFlex Messageのサンプルが表示されます。

## デザイン検討

シミュレーターのサンプルに「Hotel」があるが、ヒーロー、フッターがなくてボディのみなので、あえて「Restaurant」をもとにデザインしてみる。

## エラー時の返信と正常時の返信を分ける
```diff
class LineBotController < ApplicationController
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

    if response.key?('error')
      text = "この検索条件に該当する宿泊施設が見つかりませんでした。\n条件を変えて再検索してください。"
+      {
+        type: 'text',
+        text: text
+      }
    else
-      text = ''
-      response['hotels'].each do |hotel|
-        text <<
-          hotel[0]['hotelBasicInfo']['hotelName'] + "\n" +
-          hotel[0]['hotelBasicInfo']['hotelInformationUrl'] + "\n" +
-          "\n"
-      end
+      make_reply_content(response['hotels'])
    end

-    message = {
-      type: 'text',
-      text: text
-    }
  end
end
```

```
      {
        type: 'text',
        text: text
      }
```

エラー時はテキストでのメッセージで送信するので、そのメッセージをここで作っている

```
      make_reply_content(response['hotels'])
```
`make_reply_content`メソッドにホテル検索結果の情報を渡している。
`make_reply_content`メソッドは独自に作成するメソッドで次で作成する。

## デザイン

シミュレーターのサンプルに「Hotel」があるが、ヒーロー、フッターがなくてボディのみなので、あえて「Restaurant」をもとにデザインしてみる。

### ヒーロー

画像をタップしたときに、ホテルの詳細情報が見れるページにアクセスできるようにする


```diff
{
  "type": "bubble",
  "hero": {
    "type": "image",
    "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/01_1_cafe.png",
    "size": "full",
    "aspectRatio": "20:13",
    "aspectMode": "cover",
    "action": {
      "type": "uri",
-      "uri": "http://linecorp.com/"
+      "uri": "https://travel.rakuten.co.jp/"
    }
  },
  ・
  ・
  ・
```

実際には楽天APIのレスポンスに含まれる、楽天トラベルのサイトでのホテルのURLを設定するようにします。


### ボディ

#### ホテル名のレイアウト

```diff
・
・
・
"body": {
  "type": "box",
  "layout": "vertical",
  "contents": [
    {
      "type": "text",
-      "text": "Brown Cafe",
+      "text": "ここに楽天APIで取得したホテル名を表示",
+      "wrap": true,
      "weight": "bold",
-      "size": "xl"
+      "size": "md"
    },
・
・
・
```

wrapは、文字列が長かった時に2行目以降に折り返すかどうかを決めます。

デフォルト値はfalseで、折り返さず途中で途切れますが、長い店名の場合を考慮して、ここではtrueを指定することにしました。

また、sizeは文字サイズで、ここでは10段階ある大きさの中で下から4番目のmdにしています。

テキストコンポーネントの仕様の詳細については、以下を参照ください。

[Messaging APIリファレンス | LINE Developers](https://developers.line.biz/ja/reference/messaging-api/#f-text)

#### ホテルの評価を削除

```diff
・
・
・
"body": {
  "type": "box",
  "layout": "vertical",
  "contents": [
    {
      "type": "text",
      "text": "ここに楽天APIで取得したホテル名を表示",
      "wrap": true,
      "weight": "bold",
      "size": "md"
    },
-    {
-      "type": "box",
-      "layout": "baseline",
-      "margin": "md",
-      "contents": [
-        {
-          "type": "icon",
-          "size": "sm",
-          "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png"
-        },
        ・
        ・
        ・
-        ]
-      }
-    },
    {
      "type": "box",
      "layout": "vertical",
      "margin": "lg",
      "spacing": "sm",
      "contents": [
    ・
    ・
    ・
```

サンプルのRestaurantでは、ホテルの評価が星マークと数値で表示されていますが、今回はそうした表示は行わないので、その部分のコンポーネントは削除します。

#### 住所のレイアウト

```diff
・
・
・
"body": {
  "type": "box",
  "layout": "vertical",
  "contents": [
    ・
    ・
    ・
    {
      "type": "box",
      "layout": "vertical",
      "margin": "lg",
      "spacing": "sm",
      "contents": [
        {
          "type": "box",
          "layout": "baseline",
          "spacing": "sm",
          "contents": [
            {
              "type": "text",
-              "text": "Place",
+              "text": "住所",
              "color": "#aaaaaa",
              "size": "sm",
              "flex": 1
            },
            {
              "type": "text",
-              "text": "Miraina Tower, 4-1-6 Shinjuku, Tokyo",
+              "text": "住所を表示",
              "wrap": true,
              "color": "#666666",
              "size": "sm",
              "flex": 5
            }
          ]
        },
        ・
        ・
        ・
      ]
    }
  ]
},
・
・
・
```


#### 料金のレイアウト

```diff
・
・
・
"body": {
  "type": "box",
  "layout": "vertical",
  "contents": [
    ・
    ・
    ・
    {
      "type": "box",
      "layout": "vertical",
      "margin": "lg",
      "spacing": "sm",
      "contents": [
        {
        ・
        ・
        ・
        },
        {
          "type": "box",
          "layout": "baseline",
          "spacing": "sm",
          "contents": [
            {
              "type": "text",
-              "text": "Time",
+              "text": "料金",
              "color": "#aaaaaa",
              "size": "sm",
              "flex": 1
            },
            {
              "type": "text",
-              "text": "10:00 - 23:00",
+              "text": "最安料金を表示",
              "wrap": true,
              "color": "#666666",
              "size": "sm",
              "flex": 5
            }
          ]
        }
      ]
    }
  ]
},
・
・
・
```

### フッター

- 電話する
- 地図を見る

のボタンコンポーネントを縦に並べて表示します。

```diff
・
・
・
  "footer": {
    "type": "box",
    "layout": "vertical",
    "spacing": "sm",
    "contents": [
      {
        "type": "button",
        "style": "link",
        "height": "sm",
        "action": {
          "type": "uri",
-          "label": "CALL",
+          "label": "電話する",
          "uri": "tel:03-0000-0000"
        }
      },
      {
        "type": "button",
        "style": "link",
        "height": "sm",
        "action": {
          "type": "uri",
-          "label": "WEBSITE",
+          "label": "地図を見る",
          "uri": "https://www.google.com/maps?q=35.690921,139.700258"
        }
      },
      {
        "type": "spacer",
        "size": "sm"
      }
    ],
    "flex": 0
  }
```

## 完成形

```
{
  "type": "bubble",
  "hero": {
    "type": "image",
    "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/01_1_cafe.png",
    "size": "full",
    "aspectRatio": "20:13",
    "aspectMode": "cover",
    "action": {
      "type": "uri",
      "uri": "https://travel.rakuten.co.jp/"
    }
  },
  "body": {
    "type": "box",
    "layout": "vertical",
    "contents": [
      {
        "type": "text",
        "text": "ここに楽天APIで取得したホテル名を表示",
        "wrap": true,
        "weight": "bold",
        "size": "md"
      },
      {
        "type": "box",
        "layout": "vertical",
        "margin": "lg",
        "spacing": "sm",
        "contents": [
          {
            "type": "box",
            "layout": "baseline",
            "spacing": "sm",
            "contents": [
              {
                "type": "text",
                "text": "住所",
                "color": "#aaaaaa",
                "size": "sm",
                "flex": 1
              },
              {
                "type": "text",
                "text": "住所を表示",
                "wrap": true,
                "color": "#666666",
                "size": "sm",
                "flex": 5
              }
            ]
          },
          {
            "type": "box",
            "layout": "baseline",
            "spacing": "sm",
            "contents": [
              {
                "type": "text",
                "text": "料金",
                "color": "#aaaaaa",
                "size": "sm",
                "flex": 1
              },
              {
                "type": "text",
                "text": "最安料金を表示",
                "wrap": true,
                "color": "#666666",
                "size": "sm",
                "flex": 5
              }
            ]
          }
        ]
      }
    ]
  },
  "footer": {
    "type": "box",
    "layout": "vertical",
    "spacing": "sm",
    "contents": [
      {
        "type": "button",
        "style": "link",
        "height": "sm",
        "action": {
          "type": "uri",
          "label": "電話する",
          "uri": "tel:03-0000-0000"
        }
      },
      {
        "type": "button",
        "style": "link",
        "height": "sm",
        "action": {
          "type": "uri",
          "label": "地図を見る",
          "uri": "https://www.google.com/maps?q=35.690921,139.700258"
        }
      },
      {
        "type": "spacer",
        "size": "sm"
      }
    ],
    "flex": 0
  }
}
```

## コードに反映

### 緯度経度を世界測地系で取得するようにする

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
+        'datumType' => 1,
        'formatVersion' => 2
      }
      ・
      ・
      ・
    end
end
```

詳しい説明は省きますが、楽天APIでは緯度経度を世界測地系と日本測地系という２つの異なる基準で取得できます。

Googleマップで緯度経度をパラメータとして設定するときは世界測地系で設定する必要があります。

`datumType`を指定しない場合、日本測地系で取得するため、世界測地系で取得するようにクエリに追加します。

### Flex Messageでの返信の設定

`make_reply_content`メソッドを作成する。

```diff
class LineBotController < ApplicationController
  ・
  ・
  ・
  private
  ・
  ・
  ・
+    def make_reply_content(hotels)
+      contents = []
+      hotels.each do |hotel|
+        contents.push make_block(hotel[0]['hotelBasicInfo'])
+      end
+      {
+        "type": 'flex',
+        "altText": '宿泊検索の結果です。',
+        "contents":
+        {
+          "type": 'carousel',
+          "contents": contents
+        }
+      }
+    end
end
```
まずは編集箇所の下部のハッシュから説明します。
```
      {
        "type": 'flex',
        "altText": '宿泊検索の結果です。',
        "contents":
        {
          "type": 'carousel',
          "contents": contents
        }
      }
```

このハッシュが`reply_message`の第二引数にわたされることになります。

単純なテキストの返信をおこなうときはメッセージのタイプに`text`を設定していましたが、Flex Messageの返信をおこなうときには`flex`を設定します。

`altText`はLINEのトーク画面での最新メッセージのプレビューに何を表示するかを指定します。

通常のテキストメッセージの場合、テキストの一部がプレビューとして表示されますが、Flex Messageは表示できないので、代替テキストとして何を表示するかを`altText`で指定します。

今回は`宿泊検索の結果です。`と表示することにします。

`contents`にはFlex Messageのコンテナオブジェクトを設定します。

Flex MessageのコンテナオブジェクトにはFlex Message Simulatorで生成したJSONのデータが入ることになります。

ここでは後述する`contents`変数を設定しています。

まとめると以下のような設定になります。

|プロパティ  |タイプ |必須 |説明
|---|---|---|---|
|type |String |必須 | `flex`
|altText |String |必須 | 代替テキスト<br>最大文字数：400
|contents |Object |必須 | Flex Messageのコンテナオブジェクト

詳しくは下記を参照してください。

- [Flex Message - Messaging APIリファレンス](https://developers.line.biz/ja/reference/messaging-api/#flex-message)


```
      contents = []
      hotels.each do |hotel|
        contents.push set_bubble(hotel[0]['hotelBasicInfo'])
      end
```

Flex Messageのコンテナオブジェクトを生成しています。

`contents = []`でArray型の変数`contents`を宣言しています。

宿泊施設の情報が入った`hotels`を`each`メソッドでループさせます。

`push`メソッドは配列の末尾に要素を追加します。

> 図追加？

追加する内容は後ほど作成する`set_bubble`メソッドにホテルの詳細情報を渡した返り値です。

### バブルコンテナの作成

```diff
class LineBotController < ApplicationController
  ・
  ・
  ・
  private
    ・
    ・
    ・
    def make_reply_content(hotels)
      ・
      ・
      ・
    end

+    def set_bubble(hotel)
+      {
+        "type": "bubble",
+        "hero": set_hero(hotel),
+        "body": set_body(hotel),
+        "footer": set_footer(hotel)
+      }
+    end
end
```

`set_bubble`メソッドではバブルコンテナをセットします。

各プロバティの意味はFlex Messageの概要パートで説明しているので、そちらを参照してください。

`hero`、`body`、`footer`にはそれぞれ後ほど作成する`set_hero`、`set_body`、`set_footer`メソッドにホテルの詳細情報を渡した返り値をセットします。

### ヒーローをセット

```diff
class LineBotController < ApplicationController
  ・
  ・
  ・
  private
    ・
    ・
    ・
    def set_bubble(hotel)
      ・
      ・
      ・
    end

+    def set_hero(hotel)
+      {
+        "type": "image",
+        "url": hotel['hotelImageUrl'],
+        "size": "full",
+        "aspectRatio": "20:13",
+        "aspectMode": "cover",
+        "action": {
+          "type": "uri",
+          "uri":  hotel['hotelInformationUrl']
+        }
+      }
+    end
end
```

`url`には楽天APIから取得したホテルの画像URLをセットします。

`action`の`uri`にはホテルの詳細情報が載っている楽天トラベルURLをセットします。

### ボディをセット

```diff
class LineBotController < ApplicationController
  ・
  ・
  ・
  private
    ・
    ・
    ・
    def set_hero(hotel)
      ・
      ・
      ・
    end

+    def set_body(hotel)
+      {
+        "type": "box",
+        "layout": "vertical",
+        "contents": [
+          {
+            "type": "text",
+            "text": hotel['hotelName'],
+            "wrap": true,
+            "weight": "bold",
+            "size": "md"
+          },
+          {
+            "type": "box",
+            "layout": "vertical",
+            "margin": "lg",
+            "spacing": "sm",
+            "contents": [
+              {
+                "type": "box",
+                "layout": "baseline",
+                "spacing": "sm",
+                "contents": [
+                  {
+                    "type": "text",
+                    "text": "住所",
+                    "color": "#aaaaaa",
+                    "size": "sm",
+                    "flex": 1
+                  },
+                  {
+                    "type": "text",
+                    "text": hotel['address1'] + hotel['address2'],
+                    "wrap": true,
+                    "color": "#666666",
+                    "size": "sm",
+                    "flex": 5
+                  }
+                ]
+              },
+              {
+                "type": "box",
+                "layout": "baseline",
+                "spacing": "sm",
+                "contents": [
+                  {
+                    "type": "text",
+                    "text": "料金",
+                    "color": "#aaaaaa",
+                    "size": "sm",
+                    "flex": 1
+                  },
+                  {
+                    "type": "text",
+                    "text": '￥' + hotel['hotelMinCharge'].to_s(:delimited) + '〜',
+                    "wrap": true,
+                    "color": "#666666",
+                    "size": "sm",
+                    "flex": 5
+                  }
+                ]
+              }
+            ]
+          }
+        ]
+      }
+    end
end
```

```
"text": hotel['hotelName'],
```

ホテル名には楽天APIから取得したホテル名である`hotel['hotelName']`をセットします。

```
"text": hotel['address1'] + hotel['address2'],
```

住所は都道府県が`address1`、都道府県以下が`address2`にセットされているので、`+`演算子を使って結合させています。

```
"text": '￥' + hotel['hotelMinCharge'].to_s(:delimited) + '〜',
```

料金は`￥5,000〜`というような表記で表示させます。

楽天APIからは`5000`というように数値で取得しています。

これを`5,000`のように3桁ごとにカンマで区切るために、`to_s`メソッドでString型に変換します。

`to_s`メソッドはフォーマットを指定することができます。

3桁ごとにカンマで区切るには`.to_s(:delimited)`のように`delimited`をシンボルで指定します。

その他のフォーマットについては下記を参照してください。

- [ActiveSupport::NumericWithFormat](https://api.rubyonrails.org/classes/ActiveSupport/NumericWithFormat.html)

3桁区切りにフォーマットした料金の前後に`￥`と`〜`を`+`演算子を使って結合させています。

### フッターのセット

```diff
class LineBotController < ApplicationController
  ・
  ・
  ・
  private
    ・
    ・
    ・
    def set_body(hotel)
      ・
      ・
      ・
    end

+    def set_footer(hotel)
+      {
+        "type": "box",
+        "layout": "vertical",
+        "spacing": "sm",
+        "contents": [
+          {
+            "type": "button",
+            "style": "link",
+            "height": "sm",
+            "action": {
+              "type": "uri",
+              "label": "電話する",
+              "uri": "tel:" + hotel['telephoneNo']
+            }
+          },
+          {
+            "type": "button",
+            "style": "link",
+            "height": "sm",
+            "action": {
+              "type": "uri",
+              "label": "地図を見る",
+              "uri": "https://www.google.com/maps?q=" + hotel['latitude'].to_s + ',' + hotel['longitude'].to_s
+            }
+          },
+          {
+            "type": "spacer",
+            "size": "sm"
+          }
+        ],
+        "flex": 0
+      }
+    end
end
```

```
"uri": "tel:" + hotel['telephoneNo']
```

ホテル名には楽天APIから取得したホテルの電話番号である`hotel['telephoneNo']`をセットします。

`tel:`のあとに`+`演算子を使って結合させています。

```
"uri": "https://www.google.com/maps?q=" + hotel['latitude'].to_s + ',' + hotel['longitude'].to_s
```

GoogleマップのURLに楽天APIから取得したホテルの緯度と経度をパラメータとしてセットしています。

緯度と経度は`,`で区切るため`+`演算子で文字列結合させますが、`hotel['latitude']`と`hotel['longitude']`はInteger型です。

文字列を結合させるためにはString型に変換しなくてはならないため、それぞれ`to_s`メソッドで変換しています。