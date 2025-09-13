///|
fn main {
  let argv = @sys.get_cli_args()
  println(argv)
  // implement subcommands manually because ArgParser doesn't support subcommands yet
  let usage =
    #| Kafka CLI tool
    #| usage: 
    #|      kafka-cli <subcommand>
    #|
  guard argv.get(1) is Some(sub_command) else {
    println(usage)
    return
  }
  match sub_command {
    "consume" => {
      let usage =
        #| Kafka consumer CLI tool
        #| usage: 
        #|      kafka-cli consume --broker <broker> --topics <topics> --group <group> --offset <offset>
        #|
      let topics = @ref.new("")
      let group = @ref.new("")
      let offset = @ref.new("")
      let broker = @ref.new("")
      @ArgParser.parse(
        [
          ("--topics", "-t", Set_string(topics), "topics"),
          ("--group", "-g", Set_string(group), "group"),
          ("--offset", "-o", Set_string(offset), "offset"),
          ("--broker", "-b", Set_string(broker), "broker"),
        ],
        fn(_) {  },
        usage,
        argv,
      )
      // Assuming we use the first broker from the list for now.
      // Or handle multiple brokers appropriately, e.g., join them into a comma-separated string if your library supports it.
      let broker = match broker.val {
        "" => {
          println("Broker is required")
          return
        }
        _ => broker.val
      }
      let topics = match topics.val {
        "" => {
          println("Topics are required")
          return
        }
        _ => topics.val
      }
      let group = match group.val {
        "" => "test-group"
        _ => group.val
      }
      let offset = match offset.val {
        "earliest" | "" => @lib.Earliest
        "latest" => @lib.Latest
        _ => {
          println("Invalid offset: \{offset.val}")
          return
        }
      }
      @lib.consume(
        broker,
        topics.split(",").map(_.to_string()).to_array(),
        group,
        offset,
      ) catch {
        e => println("Error: \{e}")
      }
    }
    _ => println("Unknown subcommand: \{sub_command}")
  }
}
