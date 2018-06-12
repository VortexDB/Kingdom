require "logger"
require "yaml"

# Client of kingdom server
private class KingdomClient
  LOGS_PATH = "logs"

  # Process path
  getter path : String

  # Process
  getter process : Process

  # IO for data input
  getter io : KingdomIO

  # Logger
  getter log : Logger

  # Prepare log directory
  private def getLogFile(path : String)    
    logPath = File.join(LOGS_PATH, path)
    if !File.exists?(logPath)
      Dir.mkdir_p(logPath)
    end    

    logFilePath = File.join(logPath, "logger.log")
    return File.new(logFilePath, "w")
  end

  def initialize(@process, @path, @io)        
    @log = Logger.new(getLogFile(@path))
  end
end

# Host for services
class KingdomServer
  # Sleep time in seconds
  SLEEP_TIME = 5

  # Delay befor ping in seconds
  PING_DELAY = 5

  # Get services filename
  private def getFiles : Array(String)?
    files = Array(String).new
    data = YAML.parse(File.read("kingdom.yaml"))
    services = data["services"]        
    services.each do |name, items|
      path = File.join(".", name.to_s)
      case items.raw
      when Hash
        path? = items["path"]?
        path = path?.to_s if path
      end      

      files << path
    end
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
