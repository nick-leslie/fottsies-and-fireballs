### Footsies and fireballs

This is a fighting game engine made in the gleam programming language.
Please know that the code is not in the cleanest state because I am still experimenting.
Also, there may be spelling mistakes, and I am ok with that for now.

### dependencies and how to run
1. install gleam
2. install bun
3. install make
4. cd into the game directory and run make

NOTE: This is developed on linux, and I have not tested it on others os's
but bun and gleam are cross platforms, so it all should just work

### directory structure

Config - this is where character config files live. Please note this is a work-in-progress
editor where the game hitbox editor lives. Again, please note this is not the start
game - this is where the game rendering and client-side take place.
game_kernel - this is the actual game logic.
Server - this is where the netcode will run


### plans and todo

- [x] Input reader for non-charge special moves
- [x] Character state management
- [x] moving collisions
- [x] Sprite sheet support
- [ ] projectile support
- [ ] charge moves
- [ ] health
- [ ] player 2
- [ ] Camera work(introduce camera limits into the game kernel)
- [ ] supers
- [ ] ui


Post core game engine
- [ ] charecter move format (for hitboxes and animations)(might need to do javascript metaprograming)(or create a hashmap in game)
- [ ] build a factory for creating moves
- [ ] hitbox editor
- [ ] character config files
- [ ] Controller support
- [ ] Controller remaps

netcode plans
- [ ] server side rollback
- [ ] chashing charecter state
- [ ] peer to peer option
- [ ] Match-making server framework
- [ ] steam?

### limitations and why
Gleam compiles to javascript so it runs javascript locally.
This is not great for games; however, fighting games have few enough entities that they might work.
The main worry right now is networking within the 16ms draw window. But I wanted to try.
The reason I used gleam is because it brings me joy
