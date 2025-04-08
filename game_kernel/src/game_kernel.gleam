// import gleamy/bench
import physics/vector2
import physics/basics
import physics/collisons
import gleam/io
import gleam/list
import gleam/option
import gleam/dict
import iv
import input.{Input,Down,DownForward,Forward,InputWithAttack,Light,Neutral,Back}
import player.{Startup,State,Active,Recovery}
import raylib.{Rectangle, type Rectangle}

pub fn main() {
  let a = raylib.Rectangle(1.0,0.0,1.0,0.0)
  let b = raylib.Rectangle(1.0,0.0,1.5,0.0)
  collisons.rect_rect_gjk(a,b) |> io.debug
  // let fun = fn (list:List(raylib.Rectangle)) {
  //   use #(a,b) <- list.map(list.window_by_2(list))
  //   collisons.rect_rect_gjk(a,b)
  // }
  // bench.run([
  //   bench.Input("simple", [a,b]),
  // ],
  // [bench.Function("rect",fun)],
  // [bench.Duration(1000), bench.Warmup(100)]
  // )
  // |> bench.table([bench.IPS, bench.Min, bench.P(99)])
  // |> io.println
}

//todo this is a bad name
pub type GameKernel {
  GameKernel(
    p1:player.PlayerState,
    p1_controls:Controls,
    p2:player.PlayerState,
    p2_controls:Controls,
    world_colliders:List(player.Collider),
  )
}

//order of operaions per frame
// 1. pick state
// 2. check cancel options
// 3. swap state or continue state
// 4. run frame this updateds properties like velocity and spawns fireballs
// 5.

//todo config

pub fn new_game_kernel(sprite_scale) {
  //todo we need config files
  //todo this sprite scale stuff is stinky but its easy will make cleaner soon
  let player_col = player.make_player_world_box(xy:#(0.0 *. sprite_scale,20.0 *.sprite_scale),wh:#(50.0 *. sprite_scale,10.0*. sprite_scale))
  let p1 = player.new_player(side: 1.0,x:10.0*. sprite_scale,y:-200.0*. sprite_scale,
    states:iv.from_list([
      State("neutral",iv.from_list([
        Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_frame:option.
          Some(fn(player) {
            player.PlayerState(..player,body: basics.RiggdBody(..player.body,vel:vector2.Vector2(0.0,player.body.vel.y)))
          })
        )
      ])),
      State("forward",iv.from_list([
        Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_frame:option.
          Some(fn(player) {
            player.PlayerState(..player,body: basics.RiggdBody(..player.body,vel:vector2.add(player.body.vel,vector2.Vector2(5.0,0.0))))
          })
        )
      ])),
      State("backward",iv.from_list([
        Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_frame:option.
          Some(fn(player) {
            player.PlayerState(..player,body: basics.RiggdBody(..player.body,vel:vector2.add(player.body.vel,vector2.Vector2(-5.0,0.0))))
          })
        )
      ])),
      State("forward-quarter-circle",iv.from_list(list.flatten([
        [Startup([],player_col,[],option.Some(fn(player) {
          player.PlayerState(..player,body: basics.RiggdBody(..player.body,vel:vector2.Vector2(0.0,player.body.vel.y)))
        }))],
        Startup([],player_col,[],option.None) |> list.repeat(12),
        [Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_frame:option.Some(fn(player) {
          io.debug("ran active frame")
          player
        }))],
        Recovery([],player_col,[],option.None) |> list.repeat(5)
      ]))),
      State("DP",iv.from_list(list.flatten([
        [Startup([],player_col,[],option.Some(fn(player) {
          player.PlayerState(..player,body: basics.RiggdBody(..player.body,vel:vector2.Vector2(0.0,player.body.vel.y)))
        }))],
        Startup([],player_col,[],option.None) |> list.repeat(12),
        [Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_frame:option.Some(fn(player) {
          io.debug("ran dp active frame")
          player
        }))],
        Recovery([],player_col,[],option.None) |> list.repeat(5)
      ]))),
    ]),
  )
  |> player.add_new_pattern(input:[Input(Neutral)],state_index: 0, priority:0)
  |> player.add_new_pattern(input:[Input(Forward)], state_index:1,priority:0)
  |> player.add_new_pattern(input:[Input(Back)], state_index:2,priority:0)
  |> player.add_new_pattern(input:[InputWithAttack(Forward,Light),Input(DownForward),Input(Down)], state_index:3,priority:1)
  |> player.add_new_pattern(input:[InputWithAttack(Neutral,Light),Input(Forward),Input(DownForward),Input(Down)], state_index:3,priority:1)
  |> player.add_new_pattern(input:[Input(Forward),InputWithAttack(DownForward,Light),Input(Down)], state_index:3,priority:1)
  |> player.add_new_pattern(input:[InputWithAttack(DownForward,Light),Input(Down),Input(Forward)], state_index:4,priority:2)
  |> player.add_new_pattern(input:[InputWithAttack(Forward,Light),Input(DownForward),Input(Down),Input(Forward)], state_index:4,priority:2)

  let p2 = player.new_player(side:-1.0,x:100.0 *. sprite_scale,y:-200.0 *.sprite_scale,
   states:iv.from_list([
      State("neutral",iv.from_list([Startup([],player_col,[],option.None)]))
    ]))
  GameKernel(p1,new_controls(),p2,new_controls(),[
    player.WorldBox(
      Rectangle(
        x:-500.0,
        y:-200.0,
        width:50.0,
        height:1000.0
      ), fn(_point,player) {
        player.PlayerState(..player,
          body:basics.RiggdBody(..player.body,vel:vector2.Vector2(0.0,player.body.vel.y))

        )
      }
    ),
    player.WorldBox(
      Rectangle(
        x:520.0,
        y:-200.0,
        width:50.0,
        height:1000.0
      ), fn(_point,player) {
        player.PlayerState(..player,
          body:basics.RiggdBody(..player.body,vel:vector2.Vector2(0.0,player.body.vel.y))
        )
      }
    ),
    player.WorldBox(
      Rectangle(
        x:0.0,
        y:-100.0,
        width:1000.0,
        height:50.0
      ), fn(_point,player) {
        player.PlayerState(..player,
          body:basics.RiggdBody(..player.body,vel:vector2.Vector2(player.body.vel.x,0.0))
        )
      }
    ),
  ])
}



pub fn run_frame(game:GameKernel) {
  //todo we may need to run each step for each player one by one
  // let p1 = player.add_grav(game.p1) |> player.update_state(game.p1_controls.buffer)
  let p1 = player.add_grav(game.p1) |> player.update_state(game.p1_controls.buffer)
  let p2 = player.add_grav(game.p2) |> player.update_state(game.p2_controls.buffer)

  let p1 = p1 |> player.run_world_collisons(game.world_colliders)
  let p2 = p2 |> player.run_world_collisons(game.world_colliders)

  // let p1 = player.run_hurt_collions(p1,p2)
  // let p1 = player.run_hurt_collions(p2,p1)

  let p1 = p1 |> player.move_player_by_vel
  let p2 = p2 |> player.move_player_by_vel

  let p1 = p1 |> player.check_side(p2)
  let p2 = p2 |> player.check_side(p1)

  GameKernel(
    ..game,
    p1:  p1,
    p2:  p2
    // p2:  game.p2 |> player.run_frame,
  )
}

pub fn input_p1(game:GameKernel,pressed:List(input.Key)) {
  let side = case game.p1.p1_side {
    1.0 -> True
    -1.0 -> False
    _ -> panic as "we should never be any value other than true falls"
  }
  input.map_input_to_engine(
    game.p1_controls.input_map,
    game.p1_controls.attack_map,
    side,
    pressed)
  // |> io.debug
  |> update_p1_input_buffer(game,_)
}
fn update_p1_input_buffer(kernel:GameKernel,input:input.Input) {
  GameKernel(
    ..kernel,
    p1_controls:Controls(..kernel.p1_controls,
      buffer:  input.update_buffer(kernel.p1_controls.buffer,input)
    )
    //|> deque.to_list |> io.debug |> deque.from_list
  )
}

pub fn pick_state(game:GameKernel) {
  let p1 = player.update_state(game.p1,game.p1_controls.buffer)
  //let p2 = player.update_state(game.p2,game.p2_buffer)
  GameKernel(
    ..game,
    p1: p1,
    //p2:p2
  )
}


pub fn update_p1_input_map(kernel:GameKernel,map) {
  GameKernel(..kernel,p1_controls:update_input_map(kernel.p1_controls,map))
}
pub fn update_p1_attack_map(kernel:GameKernel,map) {
  GameKernel(..kernel,p1_controls:update_attack_map(kernel.p1_controls,map))
}

pub type InputMap(a) = dict.Dict(input.Key,a)

pub type Controls {
  Controls(
    buffer:input.Buffer,
    input_map:InputMap(input.Dir), //todo seperate this
    attack_map:InputMap(input.Attack), //todo seperate this
    used_keys:List(input.Key), //todo see if we can get rid of this
  )
}

pub fn new_controls() {
  Controls(input.new_input_buffer(),dict.new(),dict.new(),[])
}

pub fn update_input_map(controls:Controls,input_map) {
    let input_keys = dict.to_list(input_map) |> list.map(fn(mapping) { mapping.0})
    let attack_keys = dict.to_list(controls.attack_map) |> list.map(fn(mapping) { mapping.0})

  Controls(..controls,input_map:input_map,used_keys:list.append(attack_keys,input_keys))
}
pub fn update_attack_map(controls:Controls,attack_map) {
  let attack_keys = dict.to_list(attack_map) |> list.map(fn(mapping) { mapping.0})
  let input_keys = dict.to_list(controls.input_map) |> list.map(fn(mapping) { mapping.0})

  Controls(..controls,attack_map:attack_map,used_keys:list.append(attack_keys,input_keys))
}
