# AGENTS.md

## Project overview

IRTSW is intended to be a multiplayer real-time strategy game set in a persistent world. The world and its simulation continue running when players disconnect.

This repository is currently a minimal Godot 4.7 project. Unless the project later establishes another convention, use GDScript, Godot scenes/resources, and Godot's built-in testing and debugging facilities.

## Core game concept

- Each player owns a base deployed in the shared world.
- A deployed base remains present after its owner logs out.
- Automated production queues continue to operate while the owner is offline, provided their requirements are met.
- Deployed bases continue harvesting resources while unattended.
- A deployed, unattended base can be overrun by world mobs or attacked by another player.
- Players may recall their base to orbit. An orbiting base is removed from danger, but it also stops harvesting world resources.
- Recalling a base should therefore be a meaningful safety-versus-production decision, not merely a logout setting with no tradeoff.

These are product invariants. Do not silently change them when implementing features.

## Technical direction

Treat the persistent world as a server-authoritative simulation. Clients should submit commands and display replicated state; they should not be trusted to decide resource gains, production completion, combat results, ownership, or whether a base is safely in orbit.

Keep simulation rules separate from presentation and input code. Important game state should be representable as serializable data rather than existing only in scene-tree state. At minimum, persisted state will eventually need to cover:

- player and faction identity;
- base deployment state and world location;
- buildings, units, health, inventories, and ownership;
- resource nodes, harvesting assignments, and stored resources;
- production queue entries, costs, start times, and completion state;
- recall-to-orbit state and any recall timer or restrictions;
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

Record settled answers in project documentation and add tests around them.

## Development conventions

- Keep files focused and name scenes, scripts, resources, and tests consistently.
- Add automated tests for pure simulation rules wherever possible, especially state transitions, elapsed-time processing, queue ordering, and resource accounting.
- Test disconnect/reconnect, server restart, duplicate command, invalid ownership, and clock-skew scenarios for persistent systems.
- Avoid mixing unrelated refactors into feature changes.
- Update this file when the architecture or non-negotiable game rules change.
- Do not commit generated Godot data from `.godot/`.

## Definition of done for gameplay changes

A gameplay feature is not complete until its authoritative behavior, persistence implications, reconnect behavior, and failure cases have been considered. New persistent state should have a save/load or migration story, and important rule changes should have focused tests or a clearly documented manual verification path.
