import gleam/function
import gleam/io
import gleam/result
import gleam/option
import iv
import input
import gleam/dict
import gleam/list

type StateIndex = Int
//todo we may ned to split this up to reduce the copying
// right now we have player taking the world as a generic so we can do things like spawn fireballs
pub type PlayerState {
  PlayerState(
    p1_side:Bool,
    x:Float,
    y:Float,
    states:iv.Array(State),//todo we may  want to use dicts for this
    patterns:List(input.Pattern),
    current_state:Int,
    current_frame:Int,
    blocking:Bool,
    velocity:#(Float,Float)

  )
}

pub fn new_player(p1_side:Bool,x,y,states:iv.Array(State)) -> PlayerState {
  PlayerState(
    p1_side:p1_side,
    x:x,
    y:y,
    states:states,
    patterns:list.new(),
    current_state:0,
    current_frame:0,
    blocking:False,
    velocity:#(0.0,0.0)
  )
}


pub fn add_new_pattern(player:PlayerState,input:List(input.Input),state_index:StateIndex,priority:Int) {
  //this is slower but its a one time thing and its needed for priority
  let patterns  = list.append(player.patterns,[input.Pattern(
    input,
    state_index,
    priority,
    option.None
  )])
  PlayerState(..player,patterns:patterns)
}


pub fn get_current_frame(player:PlayerState) {
  let assert Ok(player_state) = iv.get(player.states,player.current_state)
  let assert Ok(player_frame) = iv.get(player_state.frames,player.current_frame)
  player_frame
}


//---- states

pub type State {
  State(
    name:String,
    frames:iv.Array(Frame)
  )
}



pub type Frame {
  Startup(
    hurt_boxes:List(Collider),
    world_box:Collider,
    cancel_options:List(StateIndex),
  )
  Active (
    hurt_boxes:List(Collider),
    world_box:Collider,
    cancel_options:List(StateIndex),
    on_active:option.Option(fn (PlayerState) -> PlayerState), // takes in the world
    hit_boxes:List(Collider),
  )
  Recovery(
    hurt_boxes:List(Collider),
    world_box:Collider,
    cancel_options:List(StateIndex),
  )
  HitStun(
    hurt_boxes:List(Collider),
    world_box:Collider,
    cancel_options:List(StateIndex), //cancle into tech states
  )
}

pub fn update_state(player:PlayerState,buffer:input.Buffer) {
  let proposed_state = input.pick_state(buffer,player.patterns)
  case proposed_state == player.current_state {
    False -> {
      let frame = get_current_frame(player)
      case list.find(frame.cancel_options,fn (cancel_index) {cancel_index == proposed_state}) {
        Error(_) -> {
          advance_frame(player,proposed_state)
        }
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
  } |> run_frame
}

pub fn add_grav(player:PlayerState) {
  PlayerState(..player,velocity:#(player.velocity.0,10.0))
}

//todo this is breaking
fn advance_frame(player:PlayerState,next_state:StateIndex) {
  let assert Ok(state) = iv.get(player.states,player.current_state)
  case {player.current_frame == {iv.length(state.frames) - 1}} {
    False -> {
      PlayerState(..player,current_frame:player.current_frame+1)
    }
    True -> {
      PlayerState(..player,current_state:next_state,current_frame:0)
    }
  }
}

fn run_frame(player:PlayerState) {
  //todo resolve collisons and physics here
  let current_frame = get_current_frame(player)
  case current_frame {
    Active(_hurt_boxes,_world_boxes, _cansels, action, _hit_boxes) -> {
      case action {
        option.None -> player
        option.Some(action) -> action(player)
      }
    }
    _ -> player
  }
}

// ---- physics
//


pub fn move_player_by_vel(player:PlayerState) {
  PlayerState(..player,x:player.x +. player.velocity.0,y:player.y +. player.velocity.1)
}

//--- collisions

pub type Collider {
  Hitbox(
    box:Rectangle,
    hit_stun_state:State,
    hit_stun_vel:fn (#(Float,Float)) -> #(Float,Float),
    block_stun_state:State,
    block_stun_vel:fn (#(Float,Float)) -> #(Float,Float)
  )
  HurtBox(
    box:Rectangle
  )
  WorldBox(
    box:Rectangle,
    moddify_vel:fn (#(Float,Float)) -> #(Float,Float),
  )
}

pub fn make_player_world_box(wh:#(Float,Float),xy:#(Float,Float)) {
  WorldBox(Rectangle(
    width:wh.0,
    height:wh.1,
    x:xy.0,
    y:xy.1,
  ),function.identity) // todo this might be bad ish
}



pub type Rectangle {
  Rectangle(
    width:Float,
    height:Float,
    x:Float,
    y:Float
  )
}

pub type CollionInfo {
  HurtCollion(
    hit:Collider,
    moddify_vel:fn (#(Float,Float)) -> #(Float,Float),
    stun_state:State
  )
  PlayerToWorld(
    player:PlayerState,
    moddify_vel:fn (#(Float,Float)) -> #(Float,Float)
  )
}

pub fn collider_to_player_space(player:PlayerState,box:Rectangle) {
  Rectangle(..box,x:box.x +. player.x,y:box.y +. player.y)
}

pub fn run_world_collisons(self:PlayerState,world_boxes:List(Collider),colision_fn:fn(Rectangle,Rectangle) -> Bool) {
  let frame = get_current_frame(self)

  use player,col <- list.fold(world_boxes,self)
  let assert WorldBox(box,vel_fn) = col
  let player_box_rect= collider_to_player_space(self,frame.world_box.box)
  case colision_fn(player_box_rect,box) {
    False -> player
    True -> {
      //todo we need to check if moving viea a line would create a collison
      //or walk from the reverse of the vec back up
      PlayerState(..player,velocity:vel_fn(player.velocity))
    }
  }
}

fn get_hurt_collisons(self,other,colision_fn:fn(Rectangle,Rectangle) -> Bool) {
  let self_frame = get_current_frame(self)
  let other_frame = get_current_frame(other)
  //check if the other player is active and check if there hit boxes overlap with our hurt boxes
  case other_frame {
    Active(hit_box,_world_box,_cancle_options, _on_active, _hurt_box) -> {
      //if any resolve as  collision we return
      use colided_list,hit_box <- list.fold(hit_box,[])

      let assert Hitbox(_,_,_,_,_) as hit_box = hit_box
      let hit_box_rect = collider_to_player_space(other,hit_box.box)

      use colided_list,hurt_box <- list.fold(self_frame.hurt_boxes,colided_list)
      //todo check perf
      let assert HurtBox(_) as hurt_box = hurt_box

      let hurt_box_rect = collider_to_player_space(self,hurt_box.box)
      //todo if this is slow we can check distence in js land
      case colision_fn(hit_box_rect,hurt_box_rect) {
        True -> list.append(colided_list,[
          case self.blocking {
            True -> HurtCollion(hurt_box,hit_box.block_stun_vel,hit_box.block_stun_state)
            False ->  HurtCollion(hurt_box,hit_box.hit_stun_vel,hit_box.hit_stun_state)
          }
        ])
        False -> colided_list
      }
    }
    _ -> []
  }
}


//todo may want to seprate this into primatives but like for now we chillen
