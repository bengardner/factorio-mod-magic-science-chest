local ResearchChest = require "src.ResearchChest"

function main()
  -- create
  script.on_event(
    defines.events.on_built_entity,
    ResearchChest.on_built_entity
  )
  script.on_event(
    defines.events.script_raised_built,
    ResearchChest.script_raised_built
  )
  script.on_event(
    defines.events.on_entity_cloned,
    ResearchChest.on_entity_cloned
  )
  script.on_event(
    defines.events.on_robot_built_entity,
    ResearchChest.on_robot_built_entity
  )
  script.on_event(
    defines.events.script_raised_revive,
    ResearchChest.script_raised_revive
  )

  -- delete
  script.on_event(
    defines.events.on_pre_player_mined_item,
    ResearchChest.generic_destroy_handler
  )
  script.on_event(
    defines.events.on_robot_mined_entity,
    ResearchChest.generic_destroy_handler
  )
  script.on_event(
    defines.events.script_raised_destroy,
    ResearchChest.generic_destroy_handler
  )
  script.on_event(
    defines.events.on_entity_died,
    ResearchChest.on_entity_died
  )
  script.on_event(
    defines.events.on_post_entity_died,
    ResearchChest.on_post_entity_died
  )

  -- refill once per second
  script.on_nth_tick(60, ResearchChest.onTick)
end

main()
