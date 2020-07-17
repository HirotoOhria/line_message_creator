require 'line_message_creator/version'
require 'erb'
require 'json'

module LineMessageCreator
  class Error < StandardError; end

  LINE_MESSAGE_DIR = defined?(Rails) ? Rails.root.join('app/line_messages') : Pathname.new('')
  HELPER_DIR       = LINE_MESSAGE_DIR.join('helpers')

  class << self
    # @param [Array] file_names File name to read (Exclude extension).
    # @param [Hash] locals Local variable used in erb file.
    # @return [Array] [ { type: 'text', text: 'message', quickReply: '...' }, ... ]
    def create_from(*file_names, **locals)
      messages      = file_names.map  { |file_name| read_message(file_name, **locals) }
      text_messages = messages.select { |message| message.is_a?(String) }
      quick_reply   = messages.select { |message| message.is_a?(Hash) }.last

      raise(LoadError, 'Please specify a text message file.') if text_messages.empty?

      if quick_reply
        text_messages.map { |text_message| { type: 'text', text: text_message, quickReply: quick_reply } }
      else
        text_messages.map { |text_message| { type: 'text', text: text_message } }
      end
    end

    private

    def read_message(file_name, **locals)
      file_path_str = find_message_file(file_name)

      case File.extname(file_path_str)
      when '.txt'
        read_text_message(file_path_str)
      when '.erb'
        read_erb_message(file_path_str, **locals)
      when '.json'
        read_quick_reply(file_path_str)
      end
    end

    def find_message_file(file_name)
      search_path = LINE_MESSAGE_DIR.join("**/#{file_name}.*")
      Dir[search_path].first || raise(LoadError, "No such file '#{file_name}'.")
    end

    def find_helper_file(helper_name)
      search_path = HELPER_DIR.join("**/#{helper_name}.rb")
      Dir[search_path].first
    end

    def read_text_message(file_path_str)
      File.open(file_path_str).read
    end

    def read_erb_message(file_path_str, **locals)
      erb_file  = File.open(file_path_str)
      variables = {}

      if (helper_module = find_helper_module(file_path_str))
        extend helper_module
        method_names = helper_module.public_instance_methods(false)
        variables    = method_names.map { |method_name| [method_name, send(method_name)] }.to_h
      end

      ERB.new(erb_file.read)
        .result_with_hash(**variables, **locals)
        .gsub(/^\s+/, '')
    end

    def find_helper_module(file_path_str)
      retry_counter = 0
      helper_name   = file_path_str.split('/').last.split('.').first + '_helper'
      return unless find_helper_file(helper_name)

      begin
        to_const(helper_name)
      rescue NameError
        retry_counter += 1
        if retry_counter == 1
          require_helper(helper_name) && retry
        else
          false
        end
      end
    end

    def require_helper(helper_name)
      helper_path = find_helper_file(helper_name)
      require helper_path
    end

    def to_const(str)
      camel_str = to_camel(str)
      Object.const_get(camel_str)
    end

    def to_camel(str)
      str.split(/_/).map(&:capitalize).join
    end

    def read_quick_reply(file_path_str)
      json_file = File.open(file_path_str)
      JSON.parse(json_file.read)
    end
  end
end
