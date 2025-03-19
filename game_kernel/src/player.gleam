import gleam/result
import gleam/option
import iv
import input
import gleam/dict
import gleam/list

pub type InputMap(a) = dict.Dict(input.Key,a)
type StateIndex = Int
//todo we may ned to split this up to reduce the copying
// right now we have player taking the world as a generic so we can do things like spawn fireballs
pub type PlayerState(world) {
  PlayerState(
    p1_side:Bool,
    x:Float,
    y:Float,
    input_map:InputMap(input.Dir),
    attack_map:InputMap(input.Attack),
    used_keys:List(input.Key), //todo see if we can get rid of this
    states:iv.Array(State(world)),
    patterns:List(#(List(input.Input),StateIndex)),
    current_state:Int,
    current_frame:Int
  )
}

pub fn new_player(p1_side:Bool,x,y,states:iv.Array(State(world))) -> PlayerState(world) {
  PlayerState(
    p1_side:p1_side,
    x:x,
    y:y,
    input_map:dict.new(),
    attack_map:dict.new(),
    used_keys:list.new(),
    states:states,
    patterns:list.new(),
    current_state:0,
    current_frame:0,
  )
}


pub fn add_new_pattern(player:PlayerState(world),input:List(input.Input),state_index:StateIndex) {
  //this is slower but its a one time thing and its needed for priority
  let patterns  = list.append(player.patterns,[#(input,state_index)])
  PlayerState(..player,patterns:patterns)
}

pub fn update_input_map(player:PlayerState(world),input_map) {
  let input_keys = dict.to_list(input_map) |> list.map(fn(mapping) { mapping.0})
  let attack_keys = dict.to_list(player.attack_map) |> list.map(fn(mapping) { mapping.0})

  PlayerState(..player,input_map:input_map,used_keys:list.append(attack_keys,input_keys))
}
pub fn update_attack_map(player:PlayerState(world),attack_map) {
  let attack_keys = dict.to_list(attack_map) |> list.map(fn(mapping) { mapping.0})
  let input_keys = dict.to_list(player.input_map) |> list.map(fn(mapping) { mapping.0})

  PlayerState(..player,attack_map:attack_map,used_keys:list.append(attack_keys,input_keys))
}



fn get_current_frame(player:PlayerState(world)) {
  let assert Ok(player_state) = iv.get(player.states,player.current_state)
  let assert Ok(player_frame) = iv.get(player_state.frames,player.current_frame)
  player_frame
}


//---- states

pub type State(world) {
  State(
    name:String,
    frames:iv.Array(Frame(world))
  )
}

pub type Frame(world) {
  Startup(
    hurt_boxes:List(Rectangle),
    cancel_options:List(StateIndex),
  )
  Active (
    hurt_boxes:List(Rectangle),
    cancel_options:List(StateIndex),
    on_active:option.Option(fn (world,Bool) -> world),
    hit_boxes:List(Rectangle),
  )
  Recovery(
    hurt_boxes:List(Rectangle),
    cancel_options:List(StateIndex),

  )
}

pub fn update_state(player:PlayerState(world),buffer:input.Buffer) {
  let proposed_state = input.pick_state(buffer,player.patterns)
  case proposed_state == player.current_state {
    False -> {
      let frame = get_current_frame(player)
      case list.find(frame.cancel_options,fn (cancel_index) {cancel_index == proposed_state}) {
        Error(_) -> advance_frame(player,proposed_state)
        Ok(_) -> {
          PlayerState(
            ..player,
            current_state:proposed_state,
            current_frame:0,
        )
        }
      }
    }
    True -> {
      advance_frame(player,0)
    }
  }
}

fn advance_frame(player:PlayerState(world),next_state:StateIndex) {
  let assert Ok(state) = iv.get(player.states,player.current_state)
  case iv.length(state.frames) == player.current_frame {
    False -> {
      PlayerState(..player,current_frame:player.current_frame+1)
    }
    True -> {
      PlayerState(..player,current_state:next_state,current_frame:0)
    }
  }
}

//--- collisions

pub type CollionInfo(world) {
  CollionInfo(
    hit_box:Rectangle,
    hurt_box:Rectangle,
    colider:PlayerState(world),
    colidee:PlayerState(world),
  )
}



//todo may want to seprate this into primatives but like for now we chillen
pub type Rectangle {
  Rectangle(
    width:Float,
    height:Float,
    x:Float,
    y:Float
  )
}

pub fn check_collisons(colider:PlayerState(world),colidee:PlayerState(world),colision_fn:fn(Rectangle,Rectangle) -> Bool) {
  let colider_frame = get_current_frame(colider)
  let colidee_frame = get_current_frame(colidee)
  case colider_frame {
    Active(hit_box,_cancle_options, _on_active, _hurt_box) -> {
      //if any resolve as  collision we return
      use colided_list,hit_box <- list.fold(hit_box,[])
      let hit_box = Rectangle(..hit_box,x:hit_box.x +. colider.x,y:hit_box.y +. colider.y)
      use colided_list,hurt_box <- list.fold(colidee_frame.hurt_boxes,colided_list)

      let hurt_box = Rectangle(..hurt_box,x:hurt_box.x +. colider.x,y:hurt_box.y +. colider.y)
      case colision_fn(hit_box,hurt_box) {
        True -> list.append(colided_list,[CollionInfo(hit_box,hurt_box,colider,colidee)])
        False -> colided_list
      }

    }
    Recovery(_,_) -> []
    Startup(_,_) -> []
  }
}
