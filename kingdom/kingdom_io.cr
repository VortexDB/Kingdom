# For send/receive contracts
class KingdomIO
  # For send
  @input : IO

  # For receive
  @output : IO

  # Read contract name from IO
  private def readContractName : String
    nameSize = @output.read_bytes(Int32)
    name = @output.read_string(nameSize)    
    return name
  end

  def initialize(@input, @output)
  end

  # Send message to io
  def write(message : KingdomContract) : Void
    @input.write_bytes(message.contract.size.to_i32)
    @input << message.contract
    @input.write_bytes(message)
    @input.flush
  end

  # Read message from io
  def read : KingdomContract
    name = readContractName
    creator = KingdomContract.creators[name]?
    raise KingdomException.new("Unknown contract") if creator.nil?
    contract = creator.call(@output, IO::ByteFormat::SystemEndian)
    return contract
  end
end
