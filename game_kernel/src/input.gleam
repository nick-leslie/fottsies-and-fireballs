import gleam/io
import gleam/option
import gleam/list
import gleam/result
import gleam/deque
import gleam/dict
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

//todo could define a pattern spesific language


//todo

pub type Buffer = deque.Deque(Input)
const buffer_max = 20

pub fn new_input_buffer() {
    deque.from_list(list.repeat(Input(Neutral),buffer_max))
}

pub fn update_buffer(buffer:Buffer,input:Input) {
  let assert Ok(#(_input,buffer)) =
  deque.push_front(buffer,input)
  |> deque.pop_back

  buffer
}
type StateIndex = Int

pub fn pick_state(buffer:Buffer,patterns:List(#(List(Input),StateIndex))) {
  //algo loop through the buffer disqalifiying states that it cant be
  //then when the buffer has been looped though return the top priority state
  // could I use a tree?
  // //this is bugged because we need to start the list at the next_index-1
  let top = {
    use inputs,input <- deque.fold(buffer,patterns)
    use #(inputs,state) as input_to_state <- list.map(inputs)
    case inputs {
      [first,..rest] as no_edit -> {
        case first == input {
          //this is were we fail I may need to re architect
          False -> #(no_edit,state)
          True -> #(rest,state)
        }
      }
      [] -> input_to_state
    }
  }|> list.filter(fn(list) {
    case list {
      #([],_state)-> True
      _ -> False
    }
  })
  |> list.last
  |> result.unwrap(#([],0))
  top.1
}


pub type Key = Int

type InputMap(a) = dict.Dict(Key,a)

pub fn map_input_to_engine(input_map:InputMap(Dir),attack_map:InputMap(Attack),is_p1_side:Bool,keys:List(Key)) -> Input {
  use current_input,key <- list.fold(keys,Input(Neutral))


  let new_dire = dict.get(input_map,key)
  |> result.unwrap(Neutral)
  |> input_to_vec
  |> ajust_side_vec(is_p1_side)
  |> add_int_vec(input_to_vec(current_input.dir))
  |> input_from_vec


  let new_attack = option.from_result(dict.get(attack_map,key))
  case current_input {
    Input(_) -> {
      case new_attack {
        option.None -> Input(new_dire)
        option.Some(any) -> InputWithAttack(new_dire,attack:any)
      }
    }
    InputWithAttack(_old_dir, attack) -> {
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
