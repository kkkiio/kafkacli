///|
struct ConsumerGroupOffsetView {
  topic : String
  partition : Int
  committed_offset : Int64
  metadata : String
} derive(ToJson)

///|
struct ConsumerGroupView {
  group_id : String
  protocol_type : String
  state : String
  group_type : String
  offsets : Array[ConsumerGroupOffsetView]?
} derive(ToJson)

///|
fn convert_offsets_for_view(
  offsets : Array[@admin.ConsumerGroupOffset],
) -> Array[ConsumerGroupOffsetView] {
  let views = Array::new()
  for offset in offsets {
    let { topic, partition, committed_offset, metadata, .. } = offset
    let metadata = match metadata {
      Some(value) => value
      None => ""
    }
    views.push(ConsumerGroupOffsetView::{
      topic,
      partition,
      committed_offset,
      metadata,
    })
  }
  views
}

///|
pub fn build_consumer_group_views(
  summaries : Array[@admin.ConsumerGroupSummary],
  offsets_map : Map[String, Array[@admin.ConsumerGroupOffset]],
  include_offsets : Bool,
) -> Array[ConsumerGroupView] {
  let views = Array::new()
  for summary in summaries {
    let group_id = summary.group_id
    let protocol_type = summary.protocol_type
    let state = summary.state
    let group_type = summary.group_type
    let offsets = if include_offsets {
      let raw_offsets = match offsets_map.get(group_id) {
        Some(items) => items
        None => []
      }
      Some(convert_offsets_for_view(raw_offsets))
    } else {
      None
    }
    views.push(ConsumerGroupView::{
      group_id,
      protocol_type,
      state,
      group_type,
      offsets,
    })
  }
  views
}

///|
pub async fn list_consumer_groups(
  bootstrap_servers : Array[String],
  describe : Bool,
) -> Unit {
  let client = @client.KafkaClient::new(@core.Config::new(), bootstrap_servers)
  let admin = @admin.KafkaClusterAdmin::new(client)
  let summaries = @admin.cluster_admin_list_consumer_groups(admin)
  let offsets_map = if describe {
    let group_ids : Array[String] = Array::new()
    for summary in summaries {
      group_ids.push(summary.group_id)
    }
    @admin.cluster_admin_describe_consumer_group_offsets(admin, group_ids)
  } else {
    Map::new()
  }
  let views = build_consumer_group_views(summaries, offsets_map, describe)
  println(views.to_json().stringify(indent=2))
}
