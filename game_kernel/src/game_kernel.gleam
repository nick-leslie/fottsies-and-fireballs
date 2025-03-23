import gleam/io
import gleam/list
import gleam/option
import gleam/dict
import iv
import input.{Input,Down,DownForward,Forward,InputWithAttack,Light,Neutral,Back}
import player.{Startup,State,Active,Recovery}
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

//todo we need to make world space

pub fn new_game_kernel() {
  //todo we need config files
  //todo we need to reverse this so special moves are high priority
  let player_col = player.make_player_world_box(#(14.0,10.0),#(-10.0,10.0))
  let p1 = player.new_player(True,-20.0,20.0,
    iv.from_list([
      State("neutral",iv.from_list([
        Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_active:option.
          Some(fn(player) {
            player.PlayerState(..player,velocity:#(0.0,player.velocity.1))
          }
          ))
      ])),
      State("forward",iv.from_list([
        Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_active:option.
          Some(fn(player) {
            player.PlayerState(..player,velocity:#(5.0,player.velocity.1))
          }
          ))
      ])),
      State("backward",iv.from_list([
        Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_active:option.
          Some(fn(player) {
            player.PlayerState(..player,velocity:#(-5.0,player.velocity.1))
          }))
      ])),
      State("forward-quarter-circle",iv.from_list(list.flatten([
        Startup([],player_col,[]) |> list.repeat(13),
        [Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_active:option.Some(fn(player) {
          io.debug("ran active frame")
          player
        }))],
        Recovery([],player_col,[]) |> list.repeat(5)
      ]))),
      State("DP",iv.from_list(list.flatten([
        Startup([],player_col,[]) |> list.repeat(13),
        [Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_active:option.Some(fn(player) {
          io.debug("ran dp active frame")
          player
        }))],
        Recovery([],player_col,[]) |> list.repeat(5)
      ]))),
    ]),
  )
  |> player.add_new_pattern([Input(Neutral)], 0,0)
  |> player.add_new_pattern([Input(Forward)], 1,0)
  |> player.add_new_pattern([Input(Back)], 2,0)
  |> player.add_new_pattern([InputWithAttack(Forward,Light),Input(DownForward),Input(Down)], 3,1)
  |> player.add_new_pattern([InputWithAttack(Neutral,Light),Input(Forward),Input(DownForward),Input(Down)], 3,1)
  |> player.add_new_pattern([Input(Forward),InputWithAttack(DownForward,Light),Input(Down)], 3,1)
  |> player.add_new_pattern([InputWithAttack(DownForward,Light),Input(Down),Input(Forward)], 4,2)
  |> player.add_new_pattern([InputWithAttack(Forward,Light),Input(DownForward),Input(Down),Input(Forward)], 4,2)

  let p2 = player.new_player(False,400.0,400.0,
    iv.from_list([
      State("neutral",iv.from_list([Startup([],player_col,[])]))
    ]))
  GameKernel(p1,new_controls(),p2,new_controls(),[player.WorldBox(
    player.Rectangle(
      x:-400.0,
      y:50.0,
      width:800.0,
      height:600.0
    ), fn(vel) {
      #(vel.0,0.0)
    }
  )])
}



pub fn run_frame(game:GameKernel,col_fn) {
  //todo we may need to run each step for each player one by one
  GameKernel(
    ..game,
    p1:  game.p1
    |> player.update_state(game.p1_controls.buffer)
    |> player.add_grav
    |> player.run_world_collisons(game.world_colliders,col_fn)
    |> player.move_player_by_vel
    // p2:  game.p2 |> player.run_frame,
  )
}

pub fn run_world_collions(game:GameKernel,colfn) {
  GameKernel(
    ..game,
    p1:  game.p1 |> player.run_world_collisons(game.world_colliders,colfn),
    // p2:  game.p2 |> player.run_frame,
  )
}

pub fn input_p1(game:GameKernel,pressed:List(input.Key)) {
  input.map_input_to_engine(
    game.p1_controls.input_map,
    game.p1_controls.attack_map,
    game.p1.p1_side,
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
