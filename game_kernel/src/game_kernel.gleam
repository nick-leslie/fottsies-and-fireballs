import gleam/io
import gleam/result
import gleam/list
import gleam/option
import gleam/dict
import iv
import gleam/deque
import input.{Input,Down,DownForward,Forward,InputWithAttack,Light,Neutral}
import player.{Startup,State,Active,Recovery}
//todo this is a bad name
pub type GameKernel {
  GameKernel(
    p1:player.PlayerState,
    p1_buffer:input.Buffer,
    p2:player.PlayerState,
  )
}



pub fn new_game_kernel() {
  //todo we need config files
  //todo we need to reverse this so special moves are high priority
  let p1 = player.new_player(True,200.0,200.0,
    iv.from_list([
      State("neutral",iv.from_list([Startup([],[1])])),
      State("forward-quarter-circle",iv.from_list(list.flatten([
        Startup([],[]) |> list.repeat(13),
        [Active(hit_boxes:[],hurt_boxes:[],cancel_options:[],on_active:option.Some(fn(player) {
          io.debug("ran active frame")
          player
        }))],
        Recovery([],[]) |> list.repeat(5)
      ]))),
      State("DP",iv.from_list(list.flatten([
        Startup([],[]) |> list.repeat(13),
        [Active(hit_boxes:[],hurt_boxes:[],cancel_options:[],on_active:option.Some(fn(player) {
          io.debug("ran dp active frame")
          player
        }))],
        Recovery([],[]) |> list.repeat(5)
      ]))),
    ]),
  )
  |> player.add_new_pattern([InputWithAttack(Forward,Light),Input(DownForward),Input(Down)], 1)
  |> player.add_new_pattern([InputWithAttack(Neutral,Light),Input(Forward),Input(DownForward),Input(Down)], 1)
  |> player.add_new_pattern([Input(Forward),InputWithAttack(DownForward,Light),Input(Down)], 1)
  |> player.add_new_pattern([InputWithAttack(DownForward,Light),Input(Down),Input(Forward)], 2)
  |> player.add_new_pattern([InputWithAttack(Forward,Light),Input(DownForward),Input(Down),Input(Forward)], 2)
  let p2 = player.new_player(False,400.0,400.0,
    iv.from_list([
      State("neutral",iv.from_list([Startup([],[])]))
    ]))
  GameKernel(p1,input.new_input_buffer(),p2)
}

pub fn input_p1(game:GameKernel,pressed:List(input.Key)) {
  input.map_input_to_engine(
    game.p1.input_map,
    game.p1.attack_map,
    game.p1.p1_side,
    pressed)
  // |> io.debug
  |> update_p1_input_buffer(game,_)
}

pub fn pick_state_p1(game:GameKernel) {
  let p1 = player.update_state(game.p1,game.p1_buffer)
  io.debug(p1.current_state)
  GameKernel(
    ..game,
    p1: p1
  )
}

fn update_p1_input_buffer(kernel:GameKernel,input:input.Input) {
  GameKernel(
    ..kernel,
    p1_buffer:input.update_buffer(kernel.p1_buffer,input)
    //|> deque.to_list |> io.debug |> deque.from_list
  )
}

pub fn update_p1_input_map(kernel:GameKernel,map) {
  GameKernel(..kernel,p1:player.update_input_map(kernel.p1,map))
}
pub fn update_p1_attack_map(kernel:GameKernel,map) {
  GameKernel(..kernel,p1:player.update_attack_map(kernel.p1,map))
}
