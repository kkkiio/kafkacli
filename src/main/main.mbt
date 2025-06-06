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
        #|      kafka-cli consume --broker <broker> --topic <topic> --group <group> --offset <offset>
        #|
      let topic = @ref.new("")
      let group = @ref.new("")
      let offset = @ref.new("")
      @ArgParser.parse(
        [
          ("--topic", "-t", Set_string(topic), "topic"),
          ("--group", "-g", Set_string(group), "group"),
          ("--offset", "-o", Set_string(offset), "offset"),
        ],
        fn(_) {  },
        usage,
        argv,
      )
      let config = try load_config() catch {
        e => {
          println("Error loading config: \{e}")
          return
        }
      }
      let current_context_name = config.current_context
      let current_context = match config.contexts.get(current_context_name) {
        Some(ctx) => ctx
        None => {
          println(
            "Current context \{current_context_name} not found in config.",
          )
          return
        }
      }
      guard current_context.brokers is [broker0, ..] else {
        println(
          "No brokers defined in current context \{current_context_name} and no --broker argument provided.",
        )
        return
      }
      // Assuming we use the first broker from the list for now.
      // Or handle multiple brokers appropriately, e.g., join them into a comma-separated string if your library supports it.
      let broker = broker0
      let topic_val = match topic.val {
        "" => {
          println("Topic is required")
          return
        }
        _ => topic.val
      }
      let group_val = match group.val {
        "" => "test-group"
        _ => group.val
      }
      let offset_val = match offset.val {
        "earliest" | "" => @lib.Earliest
        _ => {
          println("Invalid offset: \{offset.val}")
          return
        }
      }
      try @lib.consume!(broker, topic_val, group_val, offset_val) catch {
        e => println("Error: \{e}")
      }
    }
    _ => println("Unknown subcommand: \{sub_command}")
  }
}

///|
fn load_config() -> @lib.Config! {
  let env_vars = @sys.get_env_vars()
  let home_dir = match env_vars.get("HOME") {
    Some(path) => path
    None => fail!("HOME environment variable not set")
  }
  let config_path = "\{home_dir}/.kafkacli/config.json"
  if not(@fs.path_exists(config_path)) {
    fail!("Config file not found at \{config_path}")
  }
  let content = @fs.read_file_to_string!(config_path)
  let json = @json.parse!(content)
  @json.from_json!(json)
}
