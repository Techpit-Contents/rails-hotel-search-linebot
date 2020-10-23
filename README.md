# 手順書
## ルーティングの編集
```diff
Rails.application.routes.draw do
-  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
+  get 'hello/index'
end
```

## コントローラーの作成
```
$ rails generate controller hello
```

### アクション記載
```diff
class HelloController < ApplicationController
+  def index
+  end
end
```

## ビューの作成
```
$ touch ./app/views/hello/index.html.erb
```

```diff
+ <h1>Hello Rails!</h1>
```

<img width="738" alt="スクリーンショット 2020-10-24 2 15 26" src="https://user-images.githubusercontent.com/25563739/97033833-e8390880-159e-11eb-920c-1e9bbfeb0c7b.png">
