require "logger"

# Client of kingdom server
class KingdomClient
  # Process path
  getter path : String

  # Process
  getter process : Process

  # IO for data input
  getter io : KingdomIO

  # Logger
  getter log : Logger

  def initialize(@process, @path, @io)
    @log = Logger.new(STDOUT)
  end
end

# Host for services
class KingdomServer
  # Services dir
  SERVICES_DIR = "services"

  # Sleep time in seconds
  SLEEP_TIME = 5

  # Delay befor ping in seconds
  PING_DELAY = 5

  # Get services filename
  private def getFiles : Array(String)?
    return unless Dir.exists?(SERVICES_DIR)

    files = Array(String).new

    Dir.each_child(SERVICES_DIR) do |dir|
      path = File.join(SERVICES_DIR, dir)
      Dir.each_child(path) do |fileName|
        filePath = File.join(SERVICES_DIR, dir, fileName)
        files << filePath
      end
    end

    return if files.empty?
    return files
  end

  # Start serices
  private def startServices(files : Array(String)) : Void
    files.each do |file|
      spawn do
        val = Process.run(file) do |proc|          
          io = KingdomIO.new(proc.input, proc.output)
          client = KingdomClient.new(proc, file, io)
          processService(proc, client)
        end
      end
    end
  end

  # Handle service process
  private def processService(process : Process, client : KingdomClient)
    # Starts ping timer
    Timer.new(seconds: PING_DELAY) do |timer|
      client.io.write(PingContract.new)
    end

    loop do
      message = client.io.read
      processMessage(client, message)
    end
  end

  # Process message from client
  private def processMessage(client : KingdomClient, message : KingdomContract) : Void
    p message

    case message
    when PingContract
      client.io.write(PongContract.new)
    when PongContract
      # TODO: reset timeout
    when LogContract
      client.log.info(message.message)
    else
      puts "Unknown contract"
    end
  end

  # Block thread forewer
  private def runForever : Void
    loop do
      sleep SLEEP_TIME
    end
  end

  # Start server
  def start : Void
    files = getFiles()
    if files.nil?
      puts "No services to process"
      exit
    end

    startServices(files)
    runForever
  end
end
