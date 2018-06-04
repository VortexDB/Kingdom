require "msgpack"

# Base contract
abstract class KingdomContract
  # Class creators
  class_property creators = Hash(String, Proc(IO, IO::ByteFormat, KingdomContract)).new

  macro mapping(**props)
    NAME = {{ @type.name.stringify }}    

    getter contract = NAME

    MessagePack.mapping({
        {{props.stringify[1...-1].id}}
    })

    def initialize({{ props.keys.map { |x| ("@" + x.stringify).id }.stringify[1...-1].id }})
    end

    KingdomContract.creators[NAME] = ->(io : IO, format : IO::ByteFormat) { self.from_io(io, format).as(KingdomContract) }
  end

  # Write to IO
  def to_io(io, format)
    data = self.to_msgpack
    io.write_bytes(data.size.to_i64)
    io.write(data)
  end  

  # Read from IO
  def self.from_io(io, format)
    dataSize = io.read_bytes(Int64)
    buff = Bytes.new(dataSize)
    io.read(buff)
    self.from_msgpack(buff)
  end
end

# Ping service
class PingContract < KingdomContract
  mapping(
    data: Bool
  )

  def initialize(@data = true)
  end
end

# Ping response
class PongContract < KingdomContract
  mapping(
    data: Bool
  )

  def initialize(@data = true)
  end
end

# Log message
class LogContract < KingdomContract
    mapping(
        message: String
    )
end