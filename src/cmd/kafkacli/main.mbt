///|
async fn main {
  let argv = @sys.get_cli_args()
  // implement subcommands manually because ArgParser doesn't support subcommands yet
  let usage =
    #| Kafka CLI tool
    #| usage: 
    #|      kafkacli <subcommand>
    #|
  guard argv.get(1) is Some(sub_command) else {
    println(usage)
    return
  }
  let logger : @pino.Logger = @pino.logger(
    "kafkacli",
    @pino.Transport::console(),
  )
  match sub_command {
    "consume" => {
      let usage =
        #| Kafka consumer CLI tool
        #| usage: 
        #|      kafkacli consume --bootstrap-server <broker> --topics <topics> --group <group> --offset <offset>
        #|
      let topics = @ref.new("")
      let group = @ref.new("")
      let offset = @ref.new("")
      let bootstrap_servers = @ref.new("")
      @ArgParser.parse(
        [
          ("--topics", "-t", Set_string(topics), "topics"),
          ("--group", "-g", Set_string(group), "group"),
          ("--offset", "-o", Set_string(offset), "offset"),
          (
            "--bootstrap-server",
            "-b",
            Set_string(bootstrap_servers),
            "bootstrap servers",
          ),
        ],
        fn(_) {  },
        usage,
        argv,
      )
      // Assuming we use the first broker from the list for now.
      // Or handle multiple brokers appropriately, e.g., join them into a comma-separated string if your library supports it.
      let bootstrap_servers = match bootstrap_servers.val {
        "" => {
          println("Broker is required")
          return
        }
        _ => bootstrap_servers.val
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
        "earliest" | "" => @core.OffsetReset::Earliest
        "latest" => @core.OffsetReset::Latest
        _ => {
          println("Invalid offset: \{offset.val}")
          return
        }
      }
      consume(
        bootstrap_servers,
        topics.split(",").map(_.to_string()).to_array(),
        group,
        offset,
      ) catch {
        e => println("Error: \{e}")
      }
    }
    "list-topics" => {
      let usage =
        #| Kafka list topics CLI tool
        #| usage:
        #|      kafkacli list-topics --bootstrap-server <broker>
        #|
      let bootstrap_servers = @ref.new("")
      @ArgParser.parse(
        [
          (
            "--bootstrap-server",
            "-b",
            Set_string(bootstrap_servers),
            "bootstrap servers",
          ),
        ],
        fn(_) {  },
        usage,
        argv,
      )
      let bootstrap_servers = match bootstrap_servers.val {
        "" => {
          println("bootstrap server is required")
          return
        }
        _ => bootstrap_servers.val
      }
      list_topics(bootstrap_servers)
    }
    "api-versions" => {
      let usage =
        #| Kafka API versions CLI tool
        #| usage:
        #|      kafkacli api-versions --bootstrap-server <broker>
        #|
      let bootstrap_servers = @ref.new("")
      @ArgParser.parse(
        [
          (
            "--bootstrap-server",
            "-b",
            Set_string(bootstrap_servers),
            "bootstrap servers",
          ),
        ],
        fn(_) {  },
        usage,
        argv,
      )
      let bootstrap_servers = match bootstrap_servers.val {
        "" => {
          println("bootstrap server is required")
          return
        }
        _ => bootstrap_servers.val
      }
      api_versions(bootstrap_servers)
    }
    "consume-partition" => {
      let usage =
        #| Kafka partition consumer CLI tool
        #| usage:
        #|      kafkacli consume-partition --topic <topic> --partition <partition> --offset <offset> --bootstrap-server <broker>
        #|
      let topic = @ref.new("")
      let partition = @ref.new("")
      let offset = @ref.new("")
      let bootstrap_servers = @ref.new("")
      @ArgParser.parse(
        [
          ("--topic", "-t", Set_string(topic), "topic to consume from"),
          (
            "--partition",
            "-p",
            Set_string(partition),
            "partition to consume from",
          ),
          (
            "--offset",
            "-o",
            Set_string(offset),
            "starting offset (-2 for oldest, -1 for newest, or specific value)",
          ),
          (
            "--bootstrap-server",
            "-b",
            Set_string(bootstrap_servers),
            "bootstrap servers",
          ),
        ],
        fn(_) {  },
        usage,
        argv,
      )
      let bootstrap_servers = match bootstrap_servers.val {
        "" => {
          println("bootstrap server is required")
          return
        }
        _ => bootstrap_servers.val.split(",").map(_.to_string()).to_array()
      }
      let topic = match topic.val {
        "" => {
          println("topic is required")
          return
        }
        _ => topic.val
      }
      let partition_str = match partition.val {
        "" => {
          println("partition is required")
          return
        }
        _ => partition.val
      }
      let partition = match (try? @strconv.parse_int(partition_str)) {
        Ok(n) => n
        Err(_) => {
          println("Invalid partition number: \{partition_str}")
          return
        }
      }
      let offset_str = match offset.val {
        "" => {
          println("offset is required")
          return
        }
        _ => offset.val
      }
      let offset = match (try? @strconv.parse_int64(offset_str)) {
        Ok(n) => n
        Err(_) => {
          println("Invalid offset number: \{offset_str}")
          return
        }
      }
      consume_partition(logger, bootstrap_servers, topic, partition, offset)
    }
    sub_command => println("Unknown subcommand: \{sub_command}")
  }
}
