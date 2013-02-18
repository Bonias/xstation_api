require "xstore/logger"

require 'socket'
require 'json'

module XStore
  class BaseClient
    extend Logger

    def logger
      @logger ||= self.class.logger
    end

    def logger= logger
      @logger = logger
    end

    def self.server_types
      {
          :developers => {
              :ip => '195.182.34.175',
              :main_port => 5102,
              :stream_port => 5103
          },
          :demo => {
              :ip => '195.182.34.175',
              :main_port => 23460,
              :stream_port => 23461
          },
          :demo_encrypted => {
              :ip => '195.182.34.23',
              :main_port => 5114,
              :stream_port => 5115
          },
          :real => {
              :ip => '195.182.34.23',
              :main_port => 5110,
              :stream_port => 5111
          }
      }
    end


    def self.options
      @options ||= {
          :log => true
      }
    end

    def options
      @options ||= self.class.options.merge(
          {
              :server_type => :demo
          }
      )
    end

    def server_type_options
      self.class.server_types[options[:server_type]]
    end

    def ip
      server_type_options[:ip]
    end

    attr_accessor :stream_session_id

    def initialize

    end

    def connect_to_socket(ip, port, options={:tries_count => 10})
      logger.debug "Connecting to: #{ip}:#{port}"
      socket = nil
      last_error = nil
      options[:tries_count].times do |i|
        begin
          socket = TCPSocket.new ip, port
        rescue => e
          last_error = e
          msg = "Can't connect to socket (#{i} try). #{e.message}"
          logger.info msg
        end
        break if socket
      end
      unless socket
        raise StandardError, "Can't connect to socket. #{last_error.message}"
      end
      socket
    end

    def socket
      @socket ||= connect_to_socket(ip, port)
    end
  end

  class StreamClient < BaseClient
    def initialize(client)
      self.stream_session_id = client.stream_session_id
      self.logger = client.logger
    end

    def port
      server_type_options[:stream_port]
    end

    def exec(cmd, arguments=nil)
      str = command(cmd, arguments)
      logger.debug "Sending command: #{str}"
      socket.write(str)
    end

    def command(command, arguments=nil)
      arguments ||= {}
      arguments[:streamSessionId] ||= stream_session_id
      self.class.command(command, arguments)
    end

    def close
      socket.close unless socket.closed?
    end

    def self.command(command, arguments=nil)
      hash = {
          :command => command.to_s,
          #:prettyPrint => true
      }
      hash.merge!(arguments) if arguments
      MultiJson.dump(hash)
    end

    def get_trades
      exec(:getTrades, nil)
    end

    def get_tick_prices(arguments=nil)
      exec(:getTickPrices, arguments)
    end

  end

  class Client < BaseClient
    def stream_client
      @stream_client ||= StreamClient.new(self)
    end

    def port
      server_type_options[:main_port]
    end

    def self.login(user_id, password)
      client = self.new
      client.login(user_id, password)
      client
    end

    def login(user_id, password)
      res = exec(:login, {:userId => user_id, :password => password})
      self.stream_session_id = res['streamSessionId']
      res
    end

    def logout
      exec(:logout)
    end

    def exec(cmd, arguments=nil)
      str = command(cmd, arguments)
      logger.debug "Sending command: #{str}"
      socket.write(str)
      rec = read_socket
      logger.debug "received: #{rec}"
      MultiJson.load(rec)
    end

    def command(command, arguments=nil)
      self.class.command(command, arguments)
    end

    def close
      socket.close unless socket.closed?
    end

    def self.command(command, arguments=nil)
      hash = {
          :command => command.to_s,
          #:prettyPrint => true
      }
      hash.merge!(:arguments => arguments) if arguments
      MultiJson.dump(hash)
    end

    def get_all_symbols
      exec(:getAllSymbols)
    end

    def all_symbols
      @all_symbols ||= get_all_symbols
    end

    def all_symbols_names
      all_symbols['returnData'].select { |h| h['categoryName'] == 'Forex' }.map { |h| h['symbol'] }
    end

    private

    def read_socket
      data = ""
      while line = socket.gets
        if line == "\n"
          return data
        else
          data << line
        end
      end
    end

  end
end
