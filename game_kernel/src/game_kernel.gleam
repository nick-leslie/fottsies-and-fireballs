import gleam/result
import gleam/list
import gleam/option
import gleam/dict

//todo this is a bad name
pub type GameKernel {
  GameKernel(
    p1:PlayerState,
    p2:PlayerState
  )
}


pub fn new_game_kernel() {
  GameKernel(new_player(True),new_player(False))
}

pub fn update_p1_input_map(kernel:GameKernel,map) {
  GameKernel(..kernel,p1:update_input_map(kernel.p1,map))
}
pub fn update_p1_attack_map(kernel:GameKernel,map) {
  GameKernel(..kernel,p1:update_attack_map(kernel.p1,map))
}

pub type InputMap(a) = dict.Dict(Key,a)

pub type PlayerState {
  PlayerState(
    p1_side:Bool,
    input_map:InputMap(Dir),
    attack_map:InputMap(Attack),
    used_keys:List(Key) //todo see if we can get rid of this
  )
}

pub fn new_player(p1_side:Bool) -> PlayerState {
  PlayerState(
    p1_side,
    dict.new(),
    dict.new(),
    list.new()
  )
}

pub fn update_input_map(player:PlayerState,input_map) {
  let input_keys = dict.to_list(input_map) |> list.map(fn(mapping) { mapping.0})
  let attack_keys = dict.to_list(player.attack_map) |> list.map(fn(mapping) { mapping.0})

  PlayerState(..player,input_map:input_map,used_keys:list.append(attack_keys,input_keys))
}
pub fn update_attack_map(player:PlayerState,attack_map) {
  let attack_keys = dict.to_list(attack_map) |> list.map(fn(mapping) { mapping.0})
  let input_keys = dict.to_list(player.input_map) |> list.map(fn(mapping) { mapping.0})

  PlayerState(..player,attack_map:attack_map,used_keys:list.append(attack_keys,input_keys))
}




pub type Dir {
  Back
  Forward
  Neutral
  Up
  UpBack
  UpForward
  Down
  DownForward
  DownBackward
}

pub type Attack {
  Light
  Medium
  Heavy
}

pub type Input {
  Input(dir:Dir)
  InputWithAttack(dir:Dir,attack:Attack)
}

pub type Key = Int



pub fn map_input_to_engine(player_state:PlayerState,keys:List(Key)) -> Input {
  use current_input,key <- list.fold(keys,Input(Neutral))


  let new_dire = dict.get(player_state.input_map,key)
  |> result.unwrap(Neutral)
  |> input_to_vec
  |> ajust_side_vec(player_state.p1_side)
  |> add_int_vec(input_to_vec(current_input.dir))
  |> input_from_vec


  let new_attack = option.from_result(dict.get(player_state.attack_map,key))
  case current_input {
    Input(_) -> {
      case new_attack {
        option.None -> Input(new_dire)
        option.Some(any) -> InputWithAttack(new_dire,attack:any)
      }
    }
    InputWithAttack(new_dire, attack) -> {
      InputWithAttack(new_dire,resolve_attack_level(attack,new_attack))
    }
  }
}


pub fn input_to_vec(input:Dir) {
  case input {
    Back -> #(-1,0)
    Down -> #(0,-1)
    DownBackward -> #(-1,-1)
    DownForward -> #(1,-1)
    Forward -> #(1,0)
    Neutral -> #(0,0)
    Up -> #(0,1)
    UpBack -> #(-1,1)
    UpForward -> #(1,1)
  }
}

fn ajust_side_vec(input:#(Int,Int),p1_side:Bool) {
  let side_mod = case p1_side {
    True -> 1
    False -> -1
  }
  #(input.0 * side_mod,input.1)
}

pub fn input_from_vec(vec) {
  case vec {
    #(-1,0) -> Back
    #(0,-1) -> Down
    #(-1,-1) -> DownBackward
    #(1,-1) -> DownForward
    #(1,0) -> Forward
    #(0,1) -> Up
    #(-1,1) -> UpBack
    #(1,1) -> UpForward
    _ -> Neutral
  }
}

pub fn add_int_vec(a:#(Int,Int),b:#(Int,Int)) {
  #(a.0+b.0,a.1+b.1)
}

pub fn resolve_attack_level(attack,new_attack) {
  case attack,new_attack {
    any,option.None ->  any
    Heavy,option.Some(_any) -> Heavy
    _,option.Some(Heavy) ->  Heavy
    Medium,option.Some(_any) -> Medium
    Light,option.Some(Medium) -> Medium
    Light,option.Some(Light) -> Light
  }
}


pub fn int_to_key(int) -> Key {
  int
}

//todo do a look up from a hash map here
