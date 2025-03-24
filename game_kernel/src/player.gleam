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

const grav_max =  10.0

pub fn add_grav(player:PlayerState) {
  //todo we may want to disable grav
  case player.velocity.1 <. grav_max {
    True -> PlayerState(..player,velocity:#(player.velocity.0,player.velocity.1 +. grav_max))
    False -> {
      PlayerState(..player,velocity:#(player.velocity.0,grav_max))
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

pub fn make_player_world_box(wh:#(Float,Float),xy:#(Float,Float)) {
  WorldBox(Rectangle(
    width:wh.0,
    height:wh.1,
    x:xy.0,
    y:xy.1,
  ),fn(_point,player) {player}) // todo this might be bad ish
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
    moddify_vel:OnCollionFn,
    stun_state:State
  )
  PlayerToWorld(
    player:PlayerState,
    moddify_vel:OnCollionFn
  )
}

pub fn collider_to_player_space(player:PlayerState,box:Rectangle) {
  Rectangle(..box,x:box.x +. player.x,y:box.y +. player.y)
}

pub fn run_world_collisons(self:PlayerState,world_boxes:List(Collider)) {
  let frame = get_current_frame(self)

  use player,col <- list.fold(world_boxes,self)
  let assert WorldBox(box,on_col) = col
  let player_box_rect= collider_to_player_space(self,frame.world_box.box)
  // let start = birl.now()

  let may_collide = line_rect_collision(
    #(player_box_rect.x +. player_box_rect.width /. 2.0,player_box_rect.y +. player_box_rect.height),
    //we need the devison by 2
    #(player_box_rect.x +. self.velocity.0,{player_box_rect.y +. player_box_rect.height /. 2.0 } +. self.velocity.1)
  ,box)

  // io.debug(duration.blur(birl.difference(birl.now(),start)))
  case may_collide {
    option.None -> {
      player
    } //todo idk if this is right
    option.Some(point) -> {
      //this sucks we make so many things
      let new_player_x = {point.0 -. { frame.world_box.box.width /. 2.0 } -. frame.world_box.box.x}|> echo
      let new_player_y = {point.1 -. frame.world_box.box.height -. frame.world_box.box.y}|> echo
      let moved_player = PlayerState(..player,
        x:new_player_x,
        y:new_player_y,
      )
      let player_box_rect= collider_to_player_space(moved_player,frame.world_box.box)

      let has_collided = collison_rect(player_box_rect,box) |> echo
      //todo move the colider to the point
      case has_collided {
        False -> moved_player
        True -> {
          //todo we need to check if moving viea a line would create a collison
          //or walk from the reverse of the vec back up
          // moved_player
          on_col(point,moved_player)
        }
      }
    }
  }
}

fn collison_rect(rect1:Rectangle,rect2:Rectangle) {
  rect1.x <=. rect2.x +. rect2.width
  && rect1.x +. rect1.width >=. rect2.x
  && rect1.y <=. rect2.y +. rect2.height
  && rect1.y +. rect1.height >=. rect2.y
}


pub fn line_rect_collision(
  line_start: #(Float,Float),
  line_end: #(Float,Float),
  rect:Rectangle
) -> option.Option(#(Float,Float)) {
  let #(x1, y1) = line_start
  let #(x2, y2) = line_end

  // Calculate the edges of the rectangle


  // Check intersection with each side of the rectangle
  let intersections =
    [
      line_line(x1,y1,x2,y2, rect.x,rect.y, rect.x +. rect.width,rect.y), // top
      line_line(x1,y1,x2,y2, rect.x,rect.y,rect.x, rect.y+.rect.height),    // left
      line_line(x1,y1,x2,y2, rect.x+.rect.width,rect.y, rect.x+.rect.width,rect.y+.rect.height), // Right
      line_line(x1,y1,x2,y2, rect.x,rect.y+.rect.height, rect.x+.rect.width,rect.y+.rect.height),   // bot
    ]
    |> list.filter_map(function.identity)

  // Return the first intersection point, if any
  case intersections {
    [] -> option.None
    [first, ..] -> option.Some(first)
  }
}
// Helper function to check for intersection with a line segment



pub fn line_line(
  x1: Float,
  y1: Float,
  x2: Float,
  y2: Float,
  x3: Float,
  y3: Float,
  x4: Float,
  y4: Float,
) -> Result(#(Float,Float),Nil) {
  let a1 = y2 -. y1
  let b1 = x1 -. x2
  let c1 = a1 *. x1 +. b1 *. y1
  let a2 = y4 -. y3
  let b2 = x3 -. x4
  let c2 = a2 *. x3 +. b2 *. y3
  let det = a1 *. b2 -. a2 *. b1

  case det != 0.0 {
    True -> {
      let x = {b2 *. c1 -. b1 *. c2} /. det
      let y = {a1 *. c2 -. a2 *. c1} /. det

      case
        x >=. float.min(x1, x2)
        && x <=. float.max(x1, x2)
        && x >=. float.min(x3, x4)
        && x <=. float.max(x3, x4)
        && y >=. float.min(y1, y2)
        && y <=. float.max(y1, y2)
        && y >=. float.min(y3, y4)
        && y <=. float.max(y3, y4)
      {
        True -> Ok(#(x, y))
        False -> Error(Nil)
      }
    }
    False -> Error(Nil)
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
      let start = birl.now()
      let has_collided = colision_fn(hit_box_rect,hurt_box_rect)
      io.debug(birl.difference(start,birl.now()))
      case has_collided {
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
