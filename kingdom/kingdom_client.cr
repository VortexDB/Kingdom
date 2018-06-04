# Kingdom client
class Kingdom
  @@io = KingdomIO.new(STDOUT, STDIN)

  # Connect to host
  def self.connect(&block) : Void
    spawn do
      @@io.write(PingContract.new)
      @@io.read

      block.call

      loop do
        message = @@io.read
        if message.is_a?(PingContract)
          @@io.write(PongContract.new)
        end
      end
    end

    # Lock thread
    loop do
      sleep 10
    end
  end

  # Log
  def self.log(message : String) : Void
    @@io.write(LogContract.new(
      message
    )
    )
  end
end
