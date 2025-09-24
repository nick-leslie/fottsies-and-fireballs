import player
import raylib.{Rectangle,type Rectangle}
import gleam/option
import iv
import physics/riggdbody
import physics/vector2
import gleam/list
import gleam/dict
import input.{
  Back, Down, DownForward, Forward, Input, InputWithAttack, Light, Neutral, Up,
}
//todo pull this out and make it editor stuff
pub fn inital_moves(player:  player.PlayerStats(extra_stats,extra_state), scale) {
  let player_col =
    player.make_player_world_box(xy: #(0.0 *. scale, 20.0 *. scale), wh: #(
      50.0 *. scale,
      10.0 *. scale,
    ))
  let hurtbox = player.HurtBox(Rectangle(32.0 *. scale, 32.0 *. scale, 0.0, 0.0))
  let moves =
    [
      player.Move(
        "neutral",
        iv.from_list([
          player.Active(
            hit_boxes: [],
            world_box: player_col,
            hurt_boxes: [hurtbox],
            cancel_options: [],
            on_frame: option.Some(fn(state) {
              player.PlayerState(
                ..state,
                body: riggdbody.RiggdBody(
                  ..state.body,
                  vel: vector2.Vector2(0.0, state.body.vel.y),
                ),
              )
            }),
          ),
        ]),
      ),
      player.Move(
        "forward",
        iv.from_list([
          player.Active(
            hit_boxes: [],
            world_box: player_col,
            hurt_boxes: [hurtbox],
            cancel_options: [],
            on_frame: option.Some(fn(state) {
              player.PlayerState(
                ..state,
                body: riggdbody.RiggdBody(
                  ..state.body,
                  vel: vector2.add(
                    state.body.vel,
                    vector2.Vector2(player.walk_speed *. state.p1_side, 0.0),
                  ),
                ),
              )
            }),
          ),
        ]),
      ),
      player.Move(
        "backward",
        iv.from_list([
          player.Active(
            hit_boxes: [],
            world_box: player_col,
            hurt_boxes: [hurtbox],
            cancel_options: [],
            on_frame: option.Some(fn(state) {
              player.PlayerState(
                ..state,
                body: riggdbody.RiggdBody(
                  ..state.body,
                  vel: vector2.add(
                    state.body.vel,
                    vector2.Vector2({player.walk_speed *. -1.0} *. state.p1_side, 0.0),
                  ),
                ),
              )
            }),
          ),
        ]),
      ),
      player.Move(
        "up",
        iv.from_list(
          list.flatten([
            player.Active(
              hit_boxes: [],
              world_box: player_col,
              hurt_boxes: [hurtbox],
              cancel_options: [],
              on_frame: option.Some(fn(player) {
                //todo add a grounded state to players
                echo " running jump"
                player.PlayerState(
                  ..player,
                  body: riggdbody.add_force(
                    player.body,
                    vector2.Vector2(0.0, -20.0),
                  ),
                )
              }),
            )
              |> list.repeat(20),
            player.Recovery([], player_col, [], option.None) |> list.repeat(40),
          ]),
        ),
      ),
      player.Move(
        "upbackward",
        iv.from_list(
          list.flatten([
            [
              player.Active(
                hit_boxes: [],
                world_box: player_col,
                hurt_boxes: [hurtbox],
                cancel_options: [],
                on_frame: option.Some(fn(state) {
                  player.PlayerState(
                    ..state,
                    body: riggdbody.add_force(
                      state.body,
                      vector2.Vector2(-40.0 *. state.p1_side, -230.0),
                    ),
                  )
                }),
              ),
            ],
            player.Recovery([], player_col, [], option.None) |> list.repeat(60),
          ]),
        ),
      ),
      player.Move(
        "upforward",
        iv.from_list(
          list.flatten([
            [
              player.Active(
                hit_boxes: [],
                world_box: player_col,
                hurt_boxes: [hurtbox],
                cancel_options: [],
                on_frame: option.Some(fn(state) {
                  player.PlayerState(
                    ..state,
                    body: riggdbody.add_force(
                      state.body,
                      vector2.Vector2(player.air_speed *. state.p1_side, -230.0),
                    ),
                  )
                }),
              ),
            ],
            player.Recovery([], player_col, [], option.None) |> list.repeat(60),
          ]),
        ),
      ),
    ]
    |> list.index_fold(player.moves, fn(states, state, index) {
      dict.insert(states, index, state)
    })



  player.PlayerStats(..player, moves: moves)
  |> player.add_new_pattern(input: [Input(Neutral)], state_index: 0, priority: 0)
  |> player.add_new_pattern(input: [Input(Forward)], state_index: 1, priority: 0)
  |> player.add_new_pattern(input: [Input(Back)], state_index: 2, priority: 0)
  |> player.add_new_pattern(input: [Input(Up)], state_index: 3, priority: 0)
  |> player.add_new_pattern(input: [Input(input.UpBack)], state_index: 4, priority: 0)
  |> player.add_new_pattern(input: [Input(input.UpForward)],state_index: 5,priority: 0,)
}
