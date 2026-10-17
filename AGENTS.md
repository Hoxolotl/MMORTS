# AGENTS.md

## Project overview

IRTSW is intended to be a multiplayer real-time strategy game set in a persistent world. The world and its simulation continue running when players disconnect.

This repository is currently a minimal Godot 4.7 project. Unless the project later establishes another convention, use GDScript, Godot scenes/resources, and Godot's built-in testing and debugging facilities.

## Core game concept

- The shared world is an effectively infinite, flat white surface divided into 1 m by 1 m squares.
- One Godot world unit represents one meter. Art and models created in Blender should use Blender's meter-based units at the same scale.
- Each player owns a base deployed in the shared world.
- Players may choose where to deploy their base on the world surface, subject to authoritative placement validation.
- The base is also the drilling installation that extracts resources from the world.
- A deployed base remains present after its owner logs out.
- Automated production queues continue to operate while the owner is offline, provided their requirements are met.
- Deployed bases continue harvesting resources while unattended.
- A deployed, unattended base can be overrun by world mobs or attacked by another player.
- Players may recall their base to orbit. An orbiting base is removed from danger, but it also stops harvesting world resources.
- Recalling a base should therefore be a meaningful safety-versus-production decision, not merely a logout setting with no tradeoff.

These are product invariants. Do not silently change them when implementing features.

## Extraction-driven mob pressure

- When a base is deployed, the authoritative simulation creates a mob spawning point exactly 3 km from the base in a random direction.
- The random spawning direction must be chosen and persisted by the authority. Clients must not choose it, and reconnects or server restarts must not reroll it.
- Mobs spawned at that point move toward and attack the deployed base over time.
- Mob attacks always grow stronger over time and arrive in increasing numbers.
- Resource extraction adds pressure: the more resources the base extracts, the faster mob strength and attack size escalate.
- Players can regulate the base's pumping rate. A higher pumping rate increases resource income but accelerates threat escalation; a lower rate slows both extraction and the rate at which attacks become stronger and larger.
- Pumping rate changes affect the rate of escalation, not the rule that mob pressure increases over time.
- Threat progression must be based on authoritative, persisted simulation state so disconnecting, reconnecting, or restarting the server cannot reset or reroll it.

Keep the extraction-versus-danger tradeoff visible and meaningful. Exact spawning cadence, escalation curves, mob composition, and pumping limits are balance decisions and should be data-driven rather than embedded across gameplay scripts.

## Gardens and attack flowers

- When a mob dies, it creates a garden on the 1 m by 1 m world square where it died. If a garden already exists on that square, the death adds power to that garden instead.
- Garden power is based on the number of mobs that have died on its square. The authoritative simulation must record each qualifying death exactly once so retries cannot duplicate garden power.
- One day after a garden is first created, it grows a stationary attack flower.
- An attack flower's damage is related to the number of mobs that died on its square. The exact damage curve should be data-driven.
- Players may send harvesters to clean up a garden before it grows an attack flower.
- Once an attack flower has grown, a combat unit must defeat the flower before a harvester can clean up the garden.
- Gardens and attack flowers are persistent world hazards. They remain in the world after nearby players disconnect or leave the area, and they must survive server restarts.
- Garden maturation uses authoritative server time or deterministic simulation ticks. A client clock must never determine whether an attack flower has grown.

Garden creation, power accumulation, maturation, flower defeat, and cleanup must be represented as authoritative state transitions. Offline catch-up must apply the same maturation rules as continuous simulation.

## Turrets, energy, and umbilicals

- A player base can build and deploy defensive turrets.
- The base has mounting points where turrets can be installed.
- A turret may deploy by driving out of the base on tracks, or it may be called down from the player's orbital pool if the player previously created and stored one there.
- A turret called from the orbital pool may be dropped anywhere allowed by authoritative placement validation.
- Every deployed turret, including an orbitally dropped turret, must remain connected to its base by an umbilical in order to operate.
- Some mobs deliberately target umbilicals. If an umbilical is cut, its turret loses power and stops working until a valid connection is restored.
- Players allocate the base's extraction output between production and defensive energy.
- Production allocation supplies construction, including the energy required for the base to build new turrets. Defensive energy is consumed when turrets fire.
- Allocation creates a tradeoff: increasing defensive energy supports turret fire, while increasing production supports constructing additional defenses and other production.
- A turret may only fire when it has an intact umbilical connection and sufficient authoritative defensive energy is available.
- By default, a mob attacks the first turret that damages it.
- Some mob types override normal turret aggro. In particular, designated flying and tank mobs attempt to reach and attack the base instead.

Turret placement, construction, orbital deployment, connectivity, energy allocation, energy consumption, targeting, and damage must all be validated by the authoritative simulation. Cutting or restoring an umbilical and spending energy must be persisted and resistant to duplicate or out-of-order commands.

## Technical direction

Treat the persistent world as a server-authoritative simulation. Clients should submit commands and display replicated state; they should not be trusted to decide resource gains, production completion, combat results, ownership, or whether a base is safely in orbit.

Keep simulation rules separate from presentation and input code. Important game state should be representable as serializable data rather than existing only in scene-tree state. At minimum, persisted state will eventually need to cover:

- player and faction identity;
- base deployment state and world location;
- buildings, units, health, inventories, and ownership;
- resource nodes, harvesting assignments, and stored resources;
- production queue entries, costs, start times, and completion state;
- recall-to-orbit state and any recall timer or restrictions;
- pumping rate, cumulative extraction, mob spawning-point location, and threat progression;
- gardens, their world squares, accumulated power, creation and maturation timestamps, and cleanup state;
- attack flowers, their source gardens, combat state, and whether they have been defeated;
- base mounting points and their installed turrets;
- turret identity, ownership, location, deployment source, health, and operational state;
- the orbital turret pool and each turret's construction and deployment state;
- umbilical routes, endpoints, connectivity, damage, and repair state;
- extraction allocation, production energy, defensive energy, and authoritative energy transactions;
- mob targets and any persistent aggro or base-targeting behavior;
- mobs, attacks, and other world changes that must survive restarts.

Use stable IDs for persistent entities. Avoid relying on transient node paths or runtime instance IDs as durable identifiers.

Time-based systems should use authoritative server time and explicit timestamps or deterministic simulation ticks. Never calculate offline production from a client's clock. Queue processing should define what happens when storage is full, prerequisites disappear, a base is destroyed, or resources become insufficient.

Persistence must survive process restarts, not only player disconnects. State changes that affect resources, production, combat, deployment, or ownership should be recoverable and resistant to duplication exploits. Prefer idempotent commands and transactional updates where practical.

## Multiplayer and security expectations

- Validate every gameplay command on the authority that owns the simulation.
- Replicate only information a player is allowed to know; persistent does not imply globally visible.
- Design reconnects and retries so the same command cannot grant rewards twice.
- Make ownership and permission checks explicit for base management and production actions.
- Keep credentials, secrets, and deployment-specific endpoints out of the repository.
- Assume clients can be modified and network messages can arrive late, twice, or out of order.

## Gameplay implementation guidance

Model base status explicitly, for example `DEPLOYED`, `RECALLING`, and `IN_ORBIT`, rather than scattering boolean flags across systems. Centralize transitions so harvesting, targeting, combat, production, and persistence respond consistently.

Production and harvesting are distinct systems: recalling to orbit stops harvesting, while the product vision says automated production continues after logout. Do not assume that orbit automatically pauses production unless a later design decision explicitly says so.

Offline simulation must use the same rules as online simulation. It may be processed continuously or caught up from timestamps, but catch-up processing must be bounded and deterministic enough to test.

Prefer data-driven definitions for units, buildings, recipes, resource types, mobs, and balance values. Avoid embedding balance constants throughout scene scripts.

## Open design questions

Do not invent permanent answers to these without documenting the decision:

- Is base recall instant, delayed, interruptible, or blocked during combat?
- Can production continue in orbit using already stored resources?
- What happens to units outside the base when it is recalled?
- Are offline bases fully attackable, protected for a limited time, or subject to other safeguards?
- How are time zones, server downtime, maintenance, and long offline periods handled?
- Is the world one continuous shard, several shards, or session-based regions backed by persistent state?
- What information about offline players and bases is visible to opponents?
- What are the defeat, rebuilding, raiding, and resource-loss rules?
- How are base placement conflicts, minimum spacing, unreachable locations, and the effectively infinite world represented and validated?
- Is the mob spawning point permanent for a base, recreated after redeployment, or otherwise relocated during the base lifecycle?
- Which combination of elapsed time, current pumping rate, and cumulative extracted resources determines mob strength, attack size, and spawn cadence?
- What lower and upper limits apply to pumping, and can pumping be stopped completely?
- What happens to spawned mobs and accumulated threat when a base is recalled, destroyed, moved, or redeployed?
- Does "one day" of garden maturation mean 24 hours of real server time or one in-game day?
- Does every mob contribute one point of garden power, or do different mob types and strengths contribute different amounts?
- If additional mobs die on a garden after its flower has grown, does the existing flower become stronger, respawn, or leave that power for a later lifecycle?
- What are an attack flower's range, targeting rules, attack cadence, and valid targets?
- Can any player fight or harvest a garden, and who receives resources or other rewards from cleaning one up?
- What happens if maturation occurs while its region is unloaded, and when must the flower be instantiated for presentation?
- Does cleaning a garden remove all accumulated power permanently, and can a garden regrow on the same square after later mob deaths?
- What resource or energy conversion connects extraction output to the production and defense allocations?
- Can allocation be changed instantly, and are there minimums, maximums, delays, or costs?
- Do production and defensive energy accumulate in storage, and what are their capacity and overflow rules?
- Are base-mounted turrets subject to the same umbilical requirement as turrets deployed away from the base?
- How are tracked turret paths chosen, and what happens if terrain, units, gardens, or enemies block deployment?
- What range or routing limits apply to umbilicals, and may they cross, branch, be buried, or connect through relays?
- How are cut umbilicals repaired or replaced, and what happens to disconnected turrets in the meantime?
- What placement restrictions, travel time, interception risk, and cost apply to orbital turret drops?
- Can turrets be recalled to the base or orbital pool, moved after deployment, captured, or destroyed permanently?
- When several turrets damage a mob at effectively the same time, how is its first attacker selected deterministically?
- Which exact mob definitions ignore turret aggro, and how do they path toward or attack the base?

Record settled answers in project documentation and add tests around them.

## Development conventions

- Keep files focused and name scenes, scripts, resources, and tests consistently.
- Treat `/Resources/` as a local, unversioned source-asset library. Never reference files there from game scenes or scripts.
- Only use external resources that are released under CC0 or are otherwise clearly CC0-compliant. Do not introduce assets with attribution, share-alike, non-commercial, or other licensing requirements without an explicit change to this policy.
- Copy only assets actually used by the game into `/Assets/`; files in `/Assets/` are distributable project content. Preserve available source and provenance information even when attribution is not legally required.
- The license for the project's original code and content has not yet been selected. Do not assume that the use of CC0 assets makes the project itself CC0 or grants any license to the project's original work.
- Track large binary asset formats in `/Assets/` with Git LFS once LFS is configured for the repository. Commit the repository's `.gitattributes` rules alongside the assets.
- Add automated tests for pure simulation rules wherever possible, especially state transitions, elapsed-time processing, queue ordering, and resource accounting.
- Test disconnect/reconnect, server restart, duplicate command, invalid ownership, and clock-skew scenarios for persistent systems.
- Avoid mixing unrelated refactors into feature changes.
- Update this file when the architecture or non-negotiable game rules change.
- Do not commit generated Godot data from `.godot/`.

## Definition of done for gameplay changes

A gameplay feature is not complete until its authoritative behavior, persistence implications, reconnect behavior, and failure cases have been considered. New persistent state should have a save/load or migration story, and important rule changes should have focused tests or a clearly documented manual verification path.
