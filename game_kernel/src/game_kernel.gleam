// import gleamy/bench
import gleam/dict
import gleam/io
import gleam/list
import gleam/option
import input.{
  Back, Down, DownForward, Forward, Input, InputWithAttack, Light, Neutral,
}
import iv
import physics/basics
import physics/collisons
import physics/vector2
import player.{Active, Recovery, Startup, State}
import charecter_factory
import raylib.{type Rectangle, Rectangle}

//todo this is a bad name
//todo setup a message buss for things like projectiles and hitting opponents
pub type GameKernel(extra_stats,extra_state) {
  GameKernel(
    p1_stats:player.PlayerStats(extra_stats,extra_state),
    p1_state: player.PlayerState(extra_state),
    p1_controls: Controls,
    p2_state: player.PlayerState(extra_state),
    p2_stats:player.PlayerStats(extra_stats,extra_state),
    p2_controls: Controls,
    world_colliders: List(player.Collider(extra_state)),
  )
}

//order of operaions per frame
// 1. pick state
// 2. check cancel options
// 3. swap state or continue state
// 4. run frame this updateds properties like velocity and spawns fireballs
// 5.

//todo config

pub fn new_game_kernel(
  sprite_scale:Float,
  p1_stats:PlayerStats(extra_stats,extra_state),
  p1_state_init:player.ExtraStateInit(stats_type),
  p2_stats:PlayerStats(extra_stats,extra_state),
  p2_state_init:player.ExtraStateInit(stats_type)) {
  //todo we need config files
  //todo this sprite scale stuff is stinky but its easy will make cleaner soon
  let player_col =
    player.make_player_world_box(
      xy: #(0.0 *. sprite_scale, 20.0 *. sprite_scale),
      wh: #(50.0 *. sprite_scale, 10.0 *. sprite_scale),
    )
    let p1_state =
    player.new_player(
      side: 1.0,
      start_pos:vector2.Vector2( x: 10.0 *. sprite_scale,y: -200.0 *. sprite_scale),
      stats:p1_stats,
      extra_state_init:p1_state_init,
    )
    let p1_stats = p1_stats
    |> charecter_factory.inital_moves(sprite_scale)
    |> player.append_states([
      State(
        "forward-quarter-circle",
        iv.from_list(
          list.flatten([
            [
              Startup(
                [],
                player_col,
                [],
                option.Some(fn(player) {
                  player.PlayerState(
                    ..player,
                    body: basics.RiggdBody(
                      ..player.body,
                      vel: vector2.Vector2(0.0, player.body.vel.y),
                    ),
                  )
                }),
              ),
            ],
            Startup([], player_col, [], option.None) |> list.repeat(12),
            [
              Active(
                hit_boxes: [],
                world_box: player_col,
                hurt_boxes: [],
                cancel_options: [],
                on_frame: option.Some(fn(player) {
                  io.debug("ran active frame")
                  player
                }),
              ),
            ],
            Recovery([], player_col, [], option.None) |> list.repeat(5),
          ]),
        ),
      ),
      State(
        "DP",
        iv.from_list(
          list.flatten([
            [
              Startup(
                [],
                player_col,
                [],
                option.Some(fn(player) {
                  player.PlayerState(
                    ..player,
                    body: basics.RiggdBody(
                      ..player.body,
                      vel: vector2.Vector2(0.0, player.body.vel.y),
                    ),
                  )
                }),
              ),
            ],
            Startup([], player_col, [], option.None) |> list.repeat(12),
            [
              Active(
                hit_boxes: [],
                world_box: player_col,
                hurt_boxes: [],
                cancel_options: [],
                on_frame: option.Some(fn(player) {
                  io.debug("ran dp active frame")
                  player
                }),
              ),
            ],
            Recovery([], player_col, [], option.None) |> list.repeat(5),
          ]),
        ),
      ),
      State(
        "Light",
        iv.from_list(
          list.flatten([
            [
              Startup(
                [],
                player_col,
                [],
                option.Some(fn(player) {
                  player.PlayerState(
                    ..player,
                    body: basics.RiggdBody(
                      ..player.body,
                      vel: vector2.Vector2(0.0, player.body.vel.y),
                    ),
                  )
                }),
              ),
            ],
            Startup([], player_col, [], option.None) |> list.repeat(3),
            [
              Active(
                hit_boxes: [
                  player.Hitbox(
                    Rectangle(70.0, 20.0, 80.0, 10.0),
                    10,
                    10,
                    fn(_point, player) {
                      player.PlayerState(
                        ..player,
                        body: basics.add_force(
                          player.body,
                          vector2.Vector2(0.0, -200.0),
                        ),
                      )
                    },
                    10,
                    player.no_mod_col,
                  ),
                ],
                world_box: player_col,
                hurt_boxes: [],
                cancel_options: [],
                on_frame: option.Some(fn(player) {
                  io.debug("ran light")
                  player
                }),
              ),
            ],
            Recovery([], player_col, [], option.None) |> list.repeat(5),
          ]),
        ),
      ),
    ])
    |> player.add_new_pattern(
      input: [InputWithAttack(Forward, Light), Input(DownForward), Input(Down)],
      state_index: 6,
      priority: 1,
    )
    |> player.add_new_pattern(
      input: [
        InputWithAttack(Neutral, Light),
        Input(Forward),
        Input(DownForward),
        Input(Down),
      ],
      state_index: 6,
      priority: 1,
    )
    |> player.add_new_pattern(
      input: [Input(Forward), InputWithAttack(DownForward, Light), Input(Down)],
      state_index: 6,
      priority: 1,
    )
    |> player.add_new_pattern(
      input: [InputWithAttack(DownForward, Light), Input(Down), Input(Forward)],
      state_index: 7,
      priority: 2,
    )
    |> player.add_new_pattern(
      input: [
        InputWithAttack(Forward, Light),
        Input(DownForward),
        Input(Down),
        Input(Forward),
      ],
      state_index: 7,
      priority: 2,
    )
    |> player.add_new_pattern(
      input: [InputWithAttack(Neutral, Light)],
      state_index: 8,
      priority: 0,
    )
    |> player.add_new_pattern(
      input: [InputWithAttack(Forward, Light)],
      state_index: 8,
      priority: 0,
    )
    |> player.add_new_pattern(
      input: [InputWithAttack(input.Back, Light)],
      state_index: 8,
      priority: 0,
    )

    let p2_state =
    player.new_player(
      side: 1.0,
      start_pos:vector2.Vector2( x: 10.0 *. sprite_scale,y: -200.0 *. sprite_scale),
      stats:p1_stats,
      extra_state_init:p1_state_init,
    )
    let p2_stats = p22_stats
    |> player.inital_states(sprite_scale)
  GameKernel(p1_stats,p1_state, new_controls(),p2_stats,p2_state, new_controls(), [
    player.WorldBox(
      Rectangle(x: -500.0, y: -200.0, width: 50.0, height: 1000.0),
      fn(_point, player) {
        player.PlayerState(
          ..player,
          body: basics.sub_force(
              player.body,
              vector2.Vector2(player.body.force.x, 0.0),
            )
            |> basics.set_vel(vector2.Vector2(0.0, player.body.vel.y)),
        )
      },
    ),
    player.WorldBox(
      Rectangle(x: 520.0, y: -200.0, width: 50.0, height: 1000.0),
      fn(_point, player) {
        player.PlayerState(
          ..player,
          body: basics.sub_force(
              player.body,
              vector2.Vector2(player.body.force.x, 0.0),
            )
            |> basics.set_vel(vector2.Vector2(0.0, player.body.vel.y)),
        )
      },
    ),
    player.WorldBox(
      Rectangle(x: 0.0, y: -100.0, width: 1000.0, height: 50.0),
      fn(_point, player) {
        player.PlayerState(
          ..player,
          grounded: True,
          body: basics.sub_force(player.body, vector2.Vector2(0.0, 9.8))
            |> basics.set_vel(vector2.Vector2(player.body.vel.x, 0.0)),
        )
      },
    ),
  ])
}

pub fn run_frame(game: GameKernel(cs)) {
  //todo we may need to run each step for each player one by one
  // let p1 = player.add_grav(game.p1) |> player.update_state(game.p1_controls.buffer)
  let p1 =
    player.add_grav(game.p1_state) |> player.update_state(game.p1_stats,game.p1_controls.buffer)
  let p2 =
    player.add_grav(game.p2_state) |> player.update_state(game.p1_stats,game.p2_controls.buffer)

  let p1 = p1 |> player.run_world_collisons(game.p1_stats,game.world_colliders)
  let p2 = p2 |> player.run_world_collisons(game.p2_stats,game.world_colliders)

  let p1 =
    player.get_hurt_collisons(p1, p2) |> player.resolve_collison_state(p1)
  let p2 =
    player.get_hurt_collisons(p2, p1) |> player.resolve_collison_state(p2)

  let p1 = p1 |> player.check_side(p2)
  let p2 = p2 |> player.check_side(p1)

  let p1 = p1 |> player.step
  let p2 = p2 |> player.step

  GameKernel(
    ..game,
    p1: p1,
    p2: p2,
    // p2:  game.p2 |> player.run_frame,
  )
}

pub fn input_p1(game: GameKernel(cs), pressed: List(input.Key)) {
  let side = case game.p1.p1_side {
    1.0 -> True
    -1.0 -> False
    _ -> panic as "we should never be any value other than a true or false"
  }
  input.map_input_to_engine(
    game.p1_controls.input_map,
    game.p1_controls.attack_map,
    side,
    pressed,
  )
  // |> io.debug
  |> update_p1_input_buffer(game, _)
}

fn update_p1_input_buffer(kernel: GameKernel(cs), input: input.Input) {
  GameKernel(
    ..kernel,
    p1_controls: Controls(
      ..kernel.p1_controls,
      buffer: input.update_buffer(kernel.p1_controls.buffer, input),
    ),
    //|> deque.to_list |> io.debug |> deque.from_list
  )
}

pub fn pick_state(game: GameKernel(cs)) {
  let p1 = player.update_state(game.p1, game.p1_controls.buffer)
  //let p2 = player.update_state(game.p2,game.p2_buffer)
  GameKernel(
    ..game,
    p1: p1,
    //p2:p2
  )
}

pub fn update_p1_input_map(kernel: GameKernel(cs), map) {
  GameKernel(..kernel, p1_controls: update_input_map(kernel.p1_controls, map))
}

pub fn update_p1_attack_map(kernel: GameKernel(cs), map) {
  GameKernel(..kernel, p1_controls: update_attack_map(kernel.p1_controls, map))
}

pub type InputMap(a) =
  dict.Dict(input.Key, a)

pub type Controls {
  Controls(
    buffer: input.Buffer,
    input_map: InputMap(input.Dir),
    //todo seperate this
    attack_map: InputMap(input.Attack),
    //todo seperate this
    used_keys: List(input.Key),
    //todo see if we can get rid of this
  )
}

pub fn new_controls() {
  Controls(input.new_input_buffer(), dict.new(), dict.new(), [])
}

pub fn update_input_map(controls: Controls, input_map) {
  let input_keys =
    dict.to_list(input_map) |> list.map(fn(mapping) { mapping.0 })
  let attack_keys =
    dict.to_list(controls.attack_map) |> list.map(fn(mapping) { mapping.0 })

  Controls(
    ..controls,
    input_map: input_map,
    used_keys: list.append(attack_keys, input_keys),
  )
}

pub fn update_attack_map(controls: Controls, attack_map) {
  let attack_keys =
    dict.to_list(attack_map) |> list.map(fn(mapping) { mapping.0 })
  let input_keys =
    dict.to_list(controls.input_map) |> list.map(fn(mapping) { mapping.0 })

  Controls(
    ..controls,
    attack_map: attack_map,
    used_keys: list.append(attack_keys, input_keys),
  )
}
