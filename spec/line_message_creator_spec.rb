require 'spec_helper'

RSpec.describe LineMessageCreator do
  describe '#create_from' do
    let(:file_names) { [] }
    let(:locals)     { {} }

    subject(:create_from) { LineMessageCreator.create_from(*file_names, **locals) }

    context '存在しないファイルを指定した時' do
      let(:file_names) { 'hoge' }

      it 'LoadErrorを発生させること' do
        expect { create_from }.to raise_error(LoadError, "No such file '#{file_names}'.")
      end
    end

    context '.txtファイルを指定した時' do
      let(:file_names) { 'txt_message' }

      it 'ファイル内の文字列を読み込むこと' do
        expect(create_from.first[:text]).to include 'This is txt message sample.'
      end
    end

    context '.erbファイルを指定した時' do
      let(:file_names) { 'erb_message' }

      it 'erbを実行した結果を返すこと' do
        expect(create_from.first[:text]).to include 'You can use erb like ruby code anything here.'
      end

      context 'オブジェクトを渡す時' do
        let(:file_names) { 'pass_object' }
        let(:locals)     { { sample_object: 'This is sample object.' } }

        it 'オブジェクトを使用した結果を返すこと' do
          expect(create_from.first[:text]).to include 'This is sample object.'
        end
      end

      context 'ヘルパーを使う時' do
        let(:file_names) { 'use_helper' }

        it 'ヘルパーを使用した結果を返すこと' do
          expect(create_from.first[:text]).to include 'Method by UseHelperHelper.'
        end
      end
    end

    context '.jsonファイルを指定した時' do
      let(:file_names)       { 'quick_reply_sample' }
      let(:quick_reply_path) { Pathname.new(__dir__).join('fixtures/quick_replies/quick_reply_sample.json') }
      let(:quick_reply_file) { File.open(quick_reply_path) }
      let(:quick_reply_hash) { JSON.parse(quick_reply_file.read) }

      context 'テキストメッセージファイルを指定しない時' do
        it 'LoadErrorを発生させること' do
          expect { create_from }.to raise_error(LoadError, 'Please specify a text message file.')
        end
      end

      context 'テキストメッセージファイルが存在する時' do
        let(:file_names) { %w[txt_message quick_reply_sample] }

        it ':quickReply キーの内容が存在すること' do
          expect(create_from.first[:quickReply]).to eq quick_reply_hash
        end
      end
    end

    context '複数のファイルを指定する時' do
      context 'テキストメッセージを2つ指定した時' do
        let(:file_names) { %w[txt_message erb_message] }

        it '2個のオブジェクトが格納されたArrayを返すこと' do
          expect(create_from.size).to eq 2
        end
      end

      context 'テキストメッセージを3つ指定した時' do
        let(:file_names) { %w[txt_message erb_message use_helper] }

        it '3個のオブジェクトが格納されたArrayを返すこと' do
          expect(create_from.size).to eq 3
        end
      end
    end
  end
end
