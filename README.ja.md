# LineMessageCreator

## Overview

LineMessageCreator は、Rails向けのViewライクなLINEメッセージ作成ツールです。
LINE Messaging API に対応したメッセージを簡単に作成することができます。
`line-bot-sdk-ruby` gem を使用することを前提としています。  

以下のドキュメントを読んで下さい。

 - https://developers.line.biz/ja/docs/messaging-api/overview/ <br>
 - https://github.com/line/line-bot-sdk-ruby

## Installation

次のように Gemfile に追加して下さい。

```ruby
gem 'line_message_creator'
```

更に、次のコマンドを実行して下さい。

    $ bundle install

もしくは、以下のコマンドでインストールできます。

    $ gem install line_message_creator

## Set Up

最初に、LineMessageCreatorの設定を行う必要があります。
2つのパラメータを設定します。
もし、あなたが Rails を使っているなら、次のコードを書いて下さい。

```ruby
# config/initializer/line_message_creator.rb

LineMessageCreator.line_message_dir = Rails.root.join('app/line_messages')
LineMessageCreator.helper_dir       = Rails.root.join('app/line_messages/helpers')
``` 

 - `LineMessageCreator.line_message_dir` は、LINE メッセージを格納するディレクトリです。
   LineMessageCreatorは、ここで設定されたディレクトリ以下からLINEメッセージのファイルを探索します。
   (e.g. `app/line_messages/**/*.*`)
   
 - `LineMessageCreator.helper_dir` は、ヘルパーファイルを格納するディレクトリです。
   LineMessageCreatorは、ここで設定されたディレクトリ以下からヘルパーファイルを探索します。
   (e.g. `app/line_messages/helpers/**/*.rb`)
   
次に、上記で設定したパスに実際にディレクトリを作成する必要があります。
あなたが Rails を使っているなら、`your/rails_root/app/line_messages` と `your/rails_root/app/line_messages/helpers` です。
以下のコマンドを実行して下さい。(あなたのワーキングディレクトリが Rails のルートディレクトリだと仮定します。)

    $ mkdir -p app/line_messages/helpers

これで準備は完了です。

## Usage

実際にLINEメッセージを書いて、送信する手順を示します。
`lien_messages` ディレクトリの中に、LINE のメッセージファイルを作成します。

例えば、次のようになります。

```text
# app/line_messages/sample_line_message.txt

ここに、好きなLINEのメッセージを書きます。
```

そのファイルを読み込むには、次のメソッドを呼び出します。
引数はLINEメッセージのファイル名です。
引数には、ファイルの拡張子を除いたファイル名を渡していることに注意して下さい。

```ruby
LineMessageCreator.create_from('sample_line_message')

#=> [{ type: "text", text: "ここに、好きなLINEのメッセージを書きます。" }]
```

実際にLINEメッセージを送信するには、以下のように書きます。

```ruby
class YourController < ApplicationController

  # 'line-bot-sdk-ruby' gem が必要です。
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_id     = credentials.line_api[:message][:channel_id]
      config.channel_secret = credentials.line_api[:message][:channel_secret_id]
      config.channel_token  = credentials.line_api[:message][:channel_token]
    }
  end

  # 応答メッセージを送信するには、リプライトークンが必要です。
  # この例では、リプライトークンを取得するコードは省略しています。
  # 重要なことは、LineMessageCreator.create_from の実行結果を、
  # そのまま client.reply_message の引数に渡すことができる点です。
  def reply(reply_token, *file_names, **locals)
    messages = LineMessageCreator.create_from(*file_names, **locals)
    client.reply_message(reply_token, messages)
  end
end
```

## Variation

対応しているLINEメッセージファイルは、以下の通りです。

|  拡張子  |  内容  |
| :----: | :---- |
|  txt  |  テキストファイルです。  |
|  erb  |  ERBファイルです。<br>ファイルの内容をERBで評価した結果をメッセージとして送信できます。  |
|  json  |  JSONファイルです。<br>クイックリプライの内容を記述します。  |

対応している LINE Messaging API の種類は、以下の通りです。

 - 応答メッセージ
 - プッシュメッセージ
 - マルチキャストメッセージ
 - ナローキャストメッセージ
 - ブロードキャストメッセージ
 - クイックリプライ
 
## ERB

RailsのViewのように、メッセージの内容をERBで記述できます。
ERB内で使用する変数は、`LineMessageCreator.create_form` の引数で渡すことができます。

例えば、次のERBファイルを作成したとします。

```erbruby
# app/line_messages/greet_message.txt.erb

こんにちは、<%= user.name %>さん。
```

上記のファイルを読み込むには、次のようにをメソッドを呼び出します。

```ruby
sample_user = User.first
LineMessageCreator.craete_form('greet_message', user: sample_user)
```

ERBファイルでは、後述するヘルパーを使用する事ができます。

## Helper

ヘルパーを使用することで、ERBファイル内で使用する変数を簡単に定義できます。

次のERBファイルがあるとします。

```erbruby
# app/line_messages/greet_message.txt.erb

日付：<%= current_data %>
こんにちは、<%= user.name %>さん。
```

ここで、 `greet_message.txt.erb` で使用するヘルパーファイルを作成します。
ファイル名は、 `<message_file_name>_heler.rb`にする必要があります。

この例では、次のようになります。

```ruby
# app/line_messages/helpers/greet_message_helper.rb

Module GreetMessageHelper
  def current_data
    current_time = Time.current
    month = current_time.month
    day   = current_time.day

    "#{month}/#{day}"
  end
end
```
 
この状態で、以下のように呼び出すことができます。
`LineMessageCreator`は自動的にヘルパーファイルを読み込みます。
 
```ruby
sample_user = User.first
LineMessageCreator.craete_form('greet_message', user: sample_user) # { current_data: object} を渡していない点に注目して下さい。
```

このヘルパーファイルの仕組みは、RailsのViewヘルパーの仕組みを目指しましたが、完璧ではありません。
ヘルパーファイルの注意点を以下にまとめます。

 - ファイル: ヘルパーファイルは、LINEメッセージファイル毎に用意する必要があります。
 
 - 探索: LINEメッセージファイルを読み込む際に、自動的にヘルパーファイルも探します。
   ヘルパーファイルが見つかった場合、`LineMessageCreator`はヘルパーファイルを読み込み、ERBファイルを評価します。
   ヘルパーファイルが見つからなかった場合、`LineMessageCreator`はヘルパーファイルを読み込まず、ERBファイルを評価します。
   
 - 命名: ヘルパーファイル名は、 `<message_file_name>_heler.rb`にする必要があります。
   また、モジュール名は、ヘルパーファイル名のキャメルケースである必要があります。
 
 - メソッド: ヘルパーファイルでは、引数を持つメソッドを定義することはできません。
   代わりに、プロックオブジェクトを返すメソッドを定義し、`proc_method.call(args)`で呼び出して下さい

## 複数のメッセージ

複数のメッセージを送信することができます。

例えば、次のようになります。

```ruby
messages = LineMessageCreator.create_from('first_message', 'second_message', 'third_message')
client.reply_message(reply_token, messages)
```

メッセージはファイル毎に送信されます。
複数のメッセージが統合されることはありません。

複数のERBファイルを送信する場合、使用する全てのオブジェクトをハッシュで渡す必要があります。

例えば、次のようになります。

```ruby
messages = LineMessageCreator.create_from('first_erb', 'second_erb', hoge: first_obj, fuga: second_obj)
client.reply_message(reply_token, messages)
```

## クイックリプライ

クイックリプライを送信することができます。
クイックリプライファイルを`LineMessageCreator.line_message_dir` で設定したディレクトリ以下に作成します。
拡張子は、 `.json`にする必要があります。

例えば、次のようになります。

```json
// app/line_messages/quick_reply.json

{
  "items": [
    {
      "type": "action",
      "imageUrl": "https://example.com/sushi.png",
      "action": {
        "type": "message",
        "label": "Sushi",
        "text": "Sushi"
      }
    },
    {
      "type": "action",
      "action": {
        "type": "location",
        "label": "Send location"
      }
    }
  ]
}
```

クイックリプライファイルは、メッセージファイルの１つとして読み込むことができます。
クイックリプライを送信するには、次のようにします。

```ruby
messages = LineMessageCreator.create_from('line_massage', 'quick_reply')
client.reply_message(reply_token, messages)
```

クイックリプライファイルを必ず最後に指定する必要はありません。

もちろん、ERBファイルと併用することもできます。

```ruby
sample_user = USer.first
messages    = LineMessageCreator.create_from('erb_massage', 'quick_reply', user: sample_user)
client.reply_message(reply_token, messages)
```

複数のクイックリプライファイルが指定された場合、最後に指定されたクイックリプライファイルが有効になります。

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the LineMessageCreator project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/line_message_creator/blob/master/CODE_OF_CONDUCT.md).
