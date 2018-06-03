# Host for services
class KingdomServer
  # Services dir
  SERVICES_DIR = "services"

  # Sleep time in seconds
  SLEEP_TIME = 5

  # Delay befor ping in seconds
  PING_DELAY = 1

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
          processService(proc, io)
        end
      end
    end
  end

  # Handle service process
  private def processService(process : Process, io : KingdomIO)
    # Starts ping timer
    Timer.new(seconds: PING_DELAY) do |timer|
      io.send(PingContract.new)
    end

    loop do
      message = io.read
      processMessage(message)
    end
  end

  # Process message from client
  private def processMessage(message : KingdomContract) : Void
      
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
