# LineMessageCreator

## Overview

Are you japanese? => [Japanese README](https://github.com/HirotoOhria/line_message_creator/blob/master/README.ja.md)

LineMessageCreator is a View-like line for Rails Message Creation Tool.
It allows you to create messages for LINE Messaging API easily.
It is based on the `line-bot-sdk-ruby` gem.

Please read the following documentation.

 - https://developers.line.biz/en/docs/messaging-api/overview/
 - https://github.com/line/line-bot-sdk-ruby

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'line_message_creator'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install line_message_creator

## Set Up

First, we need to configure LineMessageCreator.
We need to set up two parameters.
If you're using Rails, you'll write the following code

```ruby
# config/initializer/line_message_creator.rb

LineMessageCreator.line_message_dir = Rails.root.join('app/line_messages')
LineMessageCreator.helper_dir       = Rails.root.join('app/line_messages/helpers')
``` 

 - The `LineMessageCreator.line_message_dir` is an extension to the Line This is the directory where messages are stored.
   LineMessageCreator will create a line message from the directory set here. Searches for files in the message.
   (e.g. `app/line_messages/**/*.*`)
   
 - The `LineMessageCreator.helper_dir` sets the helper file to This is the directory to store the messages.
   LineMessageCreator is a helper Search for files.
   (e.g. `app/line_messages/helpers/**/*.rb`)
   
Next, you'll need to actually create the directory in the path you've set up above.
If you're using Rails, you'll need to create a directory in `your/rails_root/app/line _messages` and `your/rails_root/app/line_ messages/helpers`.
Run the following command (We'll assume your working directory is the root directory of Rails.)

    $ mkdir -p app/line_messages/helpers
    
Now you're ready to go.

## Usage

Here's how to actually write and send a LINE message.
Create a LINE message file in the `lien_messages` directory and put it in the For example

For example, you can do the following.

```text
# app/line_messages/sample_line_message.txt

Write your favorite line message here.
```

To read the file, we call the following method.
The argument is the file name of the LINE message.
Note that we are passing the file name without the file extension in the argument.

```ruby
LineMessageCreator.create_from('sample_line_message')

#=> [{ type: "text", text: "Write your favorite line message here." }]
```

To actually send a line message, write the following

```ruby
class YourController < ApplicationController

  # You need the 'line-bot-sdk-ruby' gem.
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_id     = credentials.line_api[:message][:channel_id]
      config.channel_secret = credentials.line_api[:message][:channel_secret_id]
      config.channel_token  = credentials.line_api[:message][:channel_token]
    }
  end

  # In order to send a response message, you need a reply token.
  # In this example, the code to get the ripple token is omitted.
  # It is important to note that the result of the LineMessageCreator.create_from
  # as an argument to client.reply_message.
  def reply(reply_token, *file_names, **locals)
    messages = LineMessageCreator.create_from(*file_names, **locals)
    client.reply_message(reply_token, messages)
  end
end
```

## Variation

The supported LINE message files are as follows.

|  Extension  |  Description  |
| :----: | :---- |
|  txt  |  Text file.  |
|  erb  |  ERB file. <br> You can send a message with the results of the ERB evaluation of the contents of the file.  |
|  json  |  JSON file. <br> Describes the contents of the quick reply.  |

対応している LINE Messaging API の種類は、以下の通りです。

 - Response Message
 - Push Message
 - Multicast Message
 - Narrowcast Message
 - Broadcast Message
 - Quick reply
 
## ERB

Just like the View in Rails, we can write the message content in an ERB.
The variables we use in the ERB are `LineMessageCreator.create_ You can pass in a `form` argument.

For example, suppose you create the following ERB file

```erbruby
# app/line_messages/greet_message.txt.erb

Hi, <%= user.name %>.
```

To load the above file, call the following method.

```ruby
sample_user = User.first
LineMessageCreator.craete_form('greet_message', user: sample_user)
```

In the ERB file, you can use the helpers described below.

## Helper

The helper makes it easy to define the variables to be used in the ERB file.

Suppose you have the following ERB file.

```erbruby
# app/line_messages/greet_message.txt.erb

Data：<%= current_data %>
Hi, <%= user.name %>.
```

Now, create a helper file for use in `greet_message.txt.erb`.
The file name must be `<message_file_name>_heler.rb`.

Here's what happens.

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
 
In this state, you can call the following.
The `LineMessageCreator` reads the helper file automatically.
 
```ruby
sample_user = User.first
LineMessageCreator.craete_form('greet_message', user: sample_user) # { current_data: object} を渡していない点に注目して下さい。
```

The mechanics of this helper file were intended to be like the View helper in Rails, but not as perfect as None.
The following are some notes on helper files

 - File: A helper file must be provided for each LINE message file.
 
 - Search: When loading a LINE message file, the system automatically looks for a helper file as well.
   If a helper file is found, `LineMessageCreator` looks for a helper Reads the file and evaluates the ERB file.
   If the helper file is not found, the `LineMessageCreator` calls Evaluate an ERB file without reading a helper file.
   
 - Naming: The helper file name must be `<message_file_name>_heler. rb`.
   And the module name must be a camel case of the helper file name.
 
 - Methods: It is not possible to define methods with arguments in a helper file.
   Instead, you can define a method that returns a procs object and call(args)`proc_method. call(args)`proc_method.

##  Multiple messages

You can also send multiple messages.

For example, you can send the following message.

```ruby
messages = LineMessageCreator.create_from('first_message', 'second_message', 'third_message')
client.reply_message(reply_token, messages)
```

Messages are sent file by file.
Multiple messages will not be merged.

If you send more than one ERB file, you must pass in a hash of all the objects you are using There are.

For example:

```ruby
messages = LineMessageCreator.create_from('first_erb', 'second_erb', hoge: first_obj, fuga: second_obj)
client.reply_message(reply_token, messages)
```

## Quick Reply

You can send a quick reply.
You can add a quick reply file to `LineMessageCreator.line_ Create the file under the directory specified in `Message_dir`.
The extension should be `.json`.

For example:

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

The Quick Reply file can be loaded as one of the message files.
To send a quick reply, do the following.

```ruby
messages = LineMessageCreator.create_from('line_massage', 'quick_reply')
client.reply_message(reply_token, messages)
```

You don't always have to specify the quick reply file at the end.

Of course, it can be used in conjunction with an ERB file.

```ruby
sample_user = USer.first
messages    = LineMessageCreator.create_from('erb_massage', 'quick_reply', user: sample_user)
client.reply_message(reply_token, messages)
```

If more than one quick reply file is specified, the last one specified is A quick reply file is enabled.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the LineMessageCreator project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/line_message_creator/blob/master/CODE_OF_CONDUCT.md).

