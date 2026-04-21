Roblox Lag-Compensated Combat System
A high-performance shooting and networking framework for Roblox using Luau. This system solves the "latency gap" in multiplayer shooters by rewinding the server state to match the shooter's perspective and smoothly interpolating enemy movements on the client.

Features
Lag Compensation
Rewind Logic: When a player shoots, the server uses the shooter's clientTime to determine exactly what that player saw.
Hitbox Reconstruction: The server maintains a history of all player positions for the last 1.1 seconds. It spawns invisible "rewind hitboxes" at the exact positions enemies were in during the shooter's past.
New Player Position Replication: The server manually sends player position information to all other clients instead of using Roblox's default replication. This reduces replication delay.

Client-Side Interpolation
Instead of snapping players to new positions as they arrive, the system buffers snapshots and interpolates (Lerps) between them.
Uses a configurable delay (GameConfig.INTERP_DELAY = 0.2) to ensure there is always a "future" packet to interpolate towards, resulting in smooth enemy movement even with jittery connections.

Installation
Read default.project.json to manually put the files in the correct parts of the Roblox Studio Explorer or download the repo and use Rojo to automatically sync all of the files to Roblox Studio.
