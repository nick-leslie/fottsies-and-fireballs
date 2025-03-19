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
    p1:player.PlayerState(GameKernel),
    p1_buffer:input.Buffer,
    p2:player.PlayerState(GameKernel),
  )
}



pub fn new_game_kernel() {
  //todo we need config files
  let p1 = player.new_player(True,200.0,200.0,
    iv.from_list([
      State("neutral",iv.from_list([Startup([],[1])])),
      State("forward-quarter-circle",iv.from_list([
        Startup([],[]),Startup([],[]),Startup([],[]),Startup([],[]),Startup([],[]),
        Active(hit_boxes:[],hurt_boxes:[],cancel_options:[],on_active:option.None),
        Recovery([],[]),Recovery([],[]),Recovery([],[]),Recovery([],[]),Recovery([],[])
      ]))
    ]))
  |> player.add_new_pattern([Input(Down),Input(DownForward),InputWithAttack(Forward,Light)], 1)
  |> player.add_new_pattern([Input(Down),Input(DownForward),Input(Forward),InputWithAttack(Neutral,Light)], 1)
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
  |> update_p1_input_buffer(game,_)
}

pub fn pick_state_p1(game:GameKernel) {
  GameKernel(
    ..game,
    p1:player.update_state(game.p1,game.p1_buffer)
  )
}

fn update_p1_input_buffer(kernel:GameKernel,input:input.Input) {
  GameKernel(
    ..kernel,
    p1_buffer:input.update_buffer(kernel.p1_buffer,input)
  )
}

pub fn update_p1_input_map(kernel:GameKernel,map) {
  GameKernel(..kernel,p1:player.update_input_map(kernel.p1,map))
}
pub fn update_p1_attack_map(kernel:GameKernel,map) {
  GameKernel(..kernel,p1:player.update_attack_map(kernel.p1,map))
}
