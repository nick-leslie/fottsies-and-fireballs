import gleam/order
import birl
import gleam/function
import gleam/io
import gleam/result
import gleam/option
import iv
import input
import gleam/dict
import gleam/list
import birl/duration
import gleam/float
import raylib.{Rectangle, type Rectangle}
import physics/collisons
import physics/vector2
import physics/basics


//todo if things get nasty then we do this
const grav_max =  10.0
const full_screen_max = 100 // this is the maximum distence that we are able to walk from the other player


type StateIndex = Int
//todo we may ned to split this up to reduce the copying
// right now we have player taking the world as a generic so we can do things like spawn fireballs
pub type PlayerState {
  PlayerState(
    p1_side:Float,
    body: basics.RiggdBody,
    states:iv.Array(State),//todo we may  want to use dicts for this
    patterns:List(input.Pattern),
    current_state:Int,
    current_frame:Int,
    blocking:Bool,
    charge:Int
  )
}

pub fn new_player(side p1_side:Float,x x,y y,states states:iv.Array(State)) -> PlayerState {
  PlayerState(
    p1_side:p1_side,
    body:basics.RiggdBody(vector2.Vector2(x,y),vector2.zero()),
    states:states,
    patterns:list.new(),
    current_state:0,
    current_frame:0,
    blocking:False,
    charge:0
  )
}


pub fn add_new_pattern(player:PlayerState,input input:List(input.Input),state_index state_index:StateIndex,priority priority:Int) {
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
    on_frame:option.Option(fn (PlayerState) -> PlayerState),
  )
  Active (
    hurt_boxes:List(Collider),
    world_box:Collider,
    cancel_options:List(StateIndex),
    on_frame:option.Option(fn (PlayerState) -> PlayerState),
    hit_boxes:List(Collider),
  )
  Recovery(
    hurt_boxes:List(Collider),
    world_box:Collider,
    cancel_options:List(StateIndex),
    on_frame:option.Option(fn (PlayerState) -> PlayerState),
  )
  Stun(
    hurt_boxes:List(Collider),
    world_box:Collider,
    cancel_options:List(StateIndex), //cancle into tech states
    on_frame:option.Option(fn (PlayerState) -> PlayerState),
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
  //todo we may want to disable grav
  case player.body.vel.y <. grav_max {
    True -> PlayerState(..player,body:
      basics.RiggdBody(..player.body,vel:vector2.add(player.body.vel,vector2.Vector2(0.0,grav_max)
      )))
    False -> {
      PlayerState(..player,body:
        basics.RiggdBody(..player.body,vel:vector2.Vector2(player.body.vel.x,10.0)
        ))
    }
  }
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
  case current_frame.on_frame {
    option.None -> player
    option.Some(on_frame) -> on_frame(player)
  }
}
//todo fix me
pub fn check_side(self:PlayerState,other:PlayerState) {
  //todo this is bad and I hate it
  let self_body = self.body
  let other_body = other.body
  case self_body.pos.x >=. 0.0 {
    False -> case float.compare(self_body.pos.x -. other_body.pos.x,0.0) {
      order.Eq -> PlayerState(..self,body:basics.RiggdBody(..self_body,pos:vector2.add(self.body.pos,vector2.Vector2(0.0,1.0))),p1_side:-1.0)
      order.Gt -> PlayerState(..self,p1_side:1.0)
      order.Lt -> PlayerState(..self,p1_side:-1.0)
    }
    True ->  case float.compare(self_body.pos.x -. other_body.pos.x,0.0) {
      order.Eq -> PlayerState(..self,body:basics.RiggdBody(..self_body,pos:vector2.add(self.body.pos,vector2.Vector2(0.0,1.0))),p1_side:1.0)
      order.Gt -> PlayerState(..self,p1_side:-1.0)
      order.Lt -> PlayerState(..self,p1_side:-1.0)
    }
  }
}

// ---- physics
//


pub fn move_player_by_vel(player:PlayerState) {

  PlayerState(..player,body:basics.RiggdBody(..player.body,pos:vector2.add(player.body.pos,player.body.vel)))
}

//--- collisions
type OnCollionFn = fn (#(Float,Float),PlayerState) -> PlayerState

pub type Collider {
  Hitbox(
    box:Rectangle,
    hit_stun_state:State,
    hit_stun_vel:OnCollionFn, // todo refactor
    block_stun_state:State,
    block_stun_vel:OnCollionFn
  )
  HurtBox(
    box:Rectangle
  )
  WorldBox(
    box:Rectangle,
    on_colison:OnCollionFn,
  )
}

pub fn make_player_world_box(wh wh:#(Float,Float),xy xy:#(Float,Float)) {
  WorldBox(Rectangle(
    width:wh.0,
    height:wh.1,
    x:xy.0,
    y:xy.1,
  ),fn(_point,player) {
    io.debug("gaming")
    player
  }) // todo this might be bad ish
}




pub type CollionInfo {
  HurtCollion(
    hit:Collider,
    moddify_vel:OnCollionFn,
    stun_state:State
  )
  PlayerToWorld(
    player:PlayerState,
    moddify_vel:OnCollionFn
  )
}

pub fn collider_to_player_space(player:PlayerState,box:Rectangle) {
  Rectangle(..box,x:box.x +. player.body.pos.x,y:box.y +. player.body.pos.y)
}

pub fn run_world_collisons(self:PlayerState,world_boxes:List(Collider)) {
  let frame = get_current_frame(self)
  use player,col <- list.fold(world_boxes,self)
  let assert WorldBox(box,on_col) = col

  let box_body = basics.RiggdBody(vector2.Vector2(0.0,0.0),vector2.Vector2(0.0,0.0))
  case collisons.moving_box_collision(frame.world_box.box,player.body,box,box_body) {
    Error(err) -> player
    Ok(point) -> {
        frame.world_box.box
        |> echo
        |> collisons.collider_to_body_space(player.body)
        |> echo
        |> collisons.collider_next_pos(player.body)
        |> echo
        let col = box |> echo
        // raylib.draw_rectangle(col.x -. {col.width /. 2.0 },col.y -. {col.height /. 2.0 },col.width,col.height,raylib.ray_blue)
        on_col(vector2.to_tuple(point),player)

      }
  }
}


fn get_hurt_collisons(self,other) {
  let self_frame = get_current_frame(self)
  let other_frame = get_current_frame(other)
  //check if the other player is active and check if there hit boxes overlap with our hurt boxes
  case other_frame {
    Active(hit_box,_world_box,_cancle_options, _on_active, _hurt_box) -> {
      //if any resolve as  collision we return
      use colided_list,hit_box <- list.fold(hit_box,[])

      let assert Hitbox(_,_,_,_,_) as hit_box = hit_box

      use colided_list,hurt_box <- list.fold(self_frame.hurt_boxes,colided_list)
      //todo check perf
      // case collisons.moving_box_collision(hit_box,other) {
      //   True -> list.append(colided_list,[
      //     case self.blocking {
      //       True -> HurtCollion(hurt_box,hit_box.block_stun_vel,hit_box.block_stun_state)
      //       False ->  HurtCollion(hurt_box,hit_box.hit_stun_vel,hit_box.hit_stun_state)
      //     }
      //   ])
      //   False -> colided_list
      // }
    }
    _ -> []
  }
}

//todo may want to seprate this into primatives but like for now we chillen
