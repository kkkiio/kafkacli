///|
test "build_topic_summaries formats output" {
  let replica_assignment : Map[Int, Array[Int]] = Map::new()
  replica_assignment[0] = [1, 2]
  let config_entries : Map[String, String] = Map::new()
  config_entries["cleanup.policy"] = "compact"
  let detail = @admin.TopicDetail::{
    num_partitions: 1,
    replication_factor: 2,
    replica_assignment: Some(replica_assignment),
    config_entries: Some(config_entries),
  }
  let topics : Map[String, @admin.TopicDetail] = Map::new()
  topics["users"] = detail
  let summaries = build_topic_summaries(topics)
  @json.inspect(summaries, content=[
    {
      "name": "users",
      "num_partitions": 1,
      "replication_factor": 2,
      "replica_assignment": { "0": [1, 2] },
      "config_entries": { "cleanup.policy": "compact" },
    },
  ])
}
