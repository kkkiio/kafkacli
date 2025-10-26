///|
struct TopicSummary {
  name : String
  num_partitions : Int
  replication_factor : Int
  replica_assignment : Map[Int, Array[Int]]?
  config_entries : Map[String, String]?
} derive(ToJson)

///|
pub fn build_topic_summaries(
  topic_map : Map[String, @admin.TopicDetail],
) -> Array[TopicSummary] {
  let summaries = Array::new()
  for topic_name, detail in topic_map {
    summaries.push(TopicSummary::{
      name: topic_name,
      num_partitions: detail.num_partitions,
      replication_factor: detail.replication_factor,
      replica_assignment: detail.replica_assignment,
      config_entries: detail.config_entries,
    })
  }
  summaries
}

///|
async fn fetch_topic_details(
  bootstrap_servers : Array[String],
  topics : Array[String],
) -> Map[String, @admin.TopicDetail] {
  let client = @client.KafkaClient::new(@core.Config::new(), bootstrap_servers)
  let admin = @admin.KafkaClusterAdmin::new(client)
  if topics.length() == 0 {
    @admin.cluster_admin_list_topics(admin)
  } else {
    @admin.cluster_admin_list_topics_filtered(admin, topics)
  }
}

///|
pub async fn list_topics(
  bootstrap_servers : Array[String],
  topics : Array[String],
) -> Unit {
  let topic_map = fetch_topic_details(bootstrap_servers, topics)
  let summaries = build_topic_summaries(topic_map)
  println(summaries.to_json().stringify(indent=2))
}
