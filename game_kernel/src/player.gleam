import gleam/order
import birl
import gleam/function
import gleam/io
import gleam/result
import gleam/option
import iv
import input.{Input,Up,Down,DownForward,Forward,InputWithAttack,Light,Neutral,Back}
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
//todo this should be a a generic
pub type PlayerState(charecter_state) {
  PlayerState(
    p1_side:Float,
    body: basics.RiggdBody,
    states:iv.Array(State(charecter_state)),//todo we may  want to use dicts for this
    patterns:List(input.Pattern),
    current_state:Int,
    current_frame:Int,
    blocking:Bool,
    grounded:Bool,
    charge:Int,
    charecter_state:charecter_state
  )
}

pub fn new_player(side p1_side:Float,x x,y y,scale scale,states states:List(State(charecter_state)),charecter_state charecter_state:charecter_state) -> PlayerState(charecter_state) {
  PlayerState(
    p1_side:p1_side,
    body:basics.RiggdBody(vector2.Vector2(x,y),vector2.zero()),
    states:iv.append_list(inital_states(scale),states),
    patterns:list.new(),
    current_state:0,
    current_frame:0,
    blocking:False,
    grounded:False,
    charge:0,
    charecter_state:charecter_state
  )
  |> add_new_pattern(input:[Input(Neutral)],state_index: 0, priority:0)
  |> add_new_pattern(input:[Input(Forward)], state_index:1,priority:0)
  |> add_new_pattern(input:[Input(Back)], state_index:2,priority:0)
  |> add_new_pattern(input:[Input(Up)], state_index:3,priority:0)
  |> add_new_pattern(input:[Input(input.UpForward)], state_index:4,priority:0)
  |> add_new_pattern(input:[Input(input.UpBack)], state_index:5,priority:0)
}

fn inital_states(scale) {
  let player_col = make_player_world_box(xy:#(0.0 *. scale,20.0 *.scale),wh:#(50.0 *. scale,10.0*. scale))
  iv.from_list(
  [
  State("neutral",iv.from_list([
    Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_frame:option.
      Some(fn(player) {
        PlayerState(..player,body: basics.RiggdBody(..player.body,vel:vector2.Vector2(0.0,player.body.vel.y)))
      })
    )
  ])),
  State("forward",iv.from_list([
    Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_frame:option.
      Some(fn(player) {
        PlayerState(..player,body: basics.RiggdBody(..player.body,vel:vector2.add(player.body.vel,vector2.Vector2(5.0 *. player.p1_side,0.0))))
      })
    )
  ])),
  State("backward",iv.from_list([
    Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_frame:option.
      Some(fn(player) {
        PlayerState(..player,
          body: basics.RiggdBody(..player.body,
            vel:vector2.add(player.body.vel,vector2.Vector2(-5.0 *. player.p1_side,0.0))
          ))
      })
    )
  ])),
  State("up",iv.from_list(list.flatten([
    Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_frame:option.
      Some(fn(player:PlayerState(charecter_state)) {
        //todo add a grounded state to players
        PlayerState(..player,

          body: basics.RiggdBody(..player.body,
            vel:vector2.add(player.body.vel,vector2.Vector2(0.0,-12.0))
          ))
      })
    ) |> list.repeat(20),
    Recovery([],player_col,[],option.None) |> list.repeat(40)
  ]))),
  State("upbackward",iv.from_list(list.flatten([
    [Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_frame:option.
      Some(fn(player) {
        PlayerState(..player,
          body: basics.RiggdBody(..player.body,
            vel:vector2.add(player.body.vel,vector2.Vector2(-10.0 *. player.p1_side,-30.0))
          ))
      })
    )],
    Recovery([],player_col,[],option.None) |> list.repeat(60)
  ]))),
  State("upforward",iv.from_list([
    Active(hit_boxes:[],world_box:player_col,hurt_boxes:[],cancel_options:[],on_frame:option.
      Some(fn(player) {
        PlayerState(..player,
          body: basics.RiggdBody(..player.body,
            vel:vector2.add(player.body.vel,vector2.Vector2(10.0 *. player.p1_side,-30.0))
          ))
      })
    )
  ])),
  ])
}


pub fn add_new_pattern(player:PlayerState(cs),input input:List(input.Input),state_index state_index:StateIndex,priority priority:Int) {
  //this is slower but its a one time thing and its needed for priority
  let patterns  = list.append(player.patterns,[input.Pattern(
    input,
    state_index,
    priority,
    option.None
  )])
  PlayerState(..player,patterns:patterns)
}


pub fn get_current_frame(player:PlayerState(cs)) {
  let assert Ok(player_state) = iv.get(player.states,player.current_state)
  let assert Ok(player_frame) = iv.get(player_state.frames,player.current_frame)
  player_frame
}


//---- states

pub type State(charecter_state) {
  State(
    name:String,
    frames:iv.Array(Frame(charecter_state))
  )
}



pub type Frame(charecter_state) {
  Startup(
    hurt_boxes:List(Collider(charecter_state)),
    world_box:Collider(charecter_state),
    cancel_options:List(StateIndex),
    on_frame:option.Option(fn (PlayerState(charecter_state)) -> PlayerState(charecter_state)),
  )
  Active (
    hurt_boxes:List(Collider(charecter_state)),
    world_box:Collider(charecter_state),
    cancel_options:List(StateIndex),
    on_frame:option.Option(fn (PlayerState(charecter_state)) -> PlayerState(charecter_state)),
    hit_boxes:List(Collider(charecter_state)),
  )
  Recovery(
    hurt_boxes:List(Collider(charecter_state)),
    world_box:Collider(charecter_state),
    cancel_options:List(StateIndex),
    on_frame:option.Option(fn (PlayerState(charecter_state)) -> PlayerState(charecter_state)),
  )
  Stun(
    hurt_boxes:List(Collider(charecter_state)),
    world_box:Collider(charecter_state),
    cancel_options:List(StateIndex),
    on_frame:option.Option(fn (PlayerState(charecter_state)) -> PlayerState(charecter_state)),
  )
}

pub fn update_state(player:PlayerState(cs),buffer:input.Buffer) {
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


pub fn add_grav(player:PlayerState(cs)) {
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
fn advance_frame(player:PlayerState(cs),next_state:StateIndex) {
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

fn run_frame(player:PlayerState(cs)) {
  //todo resolve collisons and physics here
  let current_frame = get_current_frame(player)
  case current_frame.on_frame {
    option.None -> player
    option.Some(on_frame) -> on_frame(player)
  }
}
//todo fix me
pub fn check_side(self:PlayerState(cs),other:PlayerState(cs)) {
  let self_body = self.body |> basics.move_by(self.body.vel)
  let other_body = other.body |> basics.move_by(self.body.vel)
  case float.compare(self_body.pos.x-.other_body.pos.x,0.0) {
    order.Eq -> PlayerState(..self,body:self_body,p1_side:1.0)
    order.Gt -> PlayerState(..self,p1_side:-1.0)
    order.Lt -> PlayerState(..self,p1_side:1.0)
  }
}

// ---- physics
//


pub fn move_player_by_vel(player:PlayerState(cs)) {

  PlayerState(..player,body:basics.RiggdBody(..player.body,pos:vector2.add(player.body.pos,player.body.vel)))
}

//--- collisions
type OnCollionFn(cs) = fn (#(Float,Float),PlayerState(cs)) -> PlayerState(cs)

pub type Collider(cs) {
  Hitbox(
    box:Rectangle,
    hit_stun_state:State(cs),
    hit_stun_vel:OnCollionFn(cs), // todo refactor
    block_stun_state:State(cs),
    block_stun_vel:OnCollionFn(cs)
  )
  HurtBox(
    box:Rectangle
  )
  WorldBox(
    box:Rectangle,
    on_colison:OnCollionFn(cs),
    //no_col_err: this is for the error we emit when there is no collison sould wrap a collsion error and another error
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




pub type CollionInfo(cs) {
  HurtCollion(
    hit:Collider(cs),
    moddify_vel:OnCollionFn(cs),
    stun_state:State(cs)
  )
  PlayerToWorld(
    player:PlayerState(cs),
    moddify_vel:OnCollionFn(cs)
  )
}

pub fn collider_to_player_space(player:PlayerState(cs),box:Rectangle) {
  Rectangle(..box,x:box.x +. player.body.pos.x,y:box.y +. player.body.pos.y)
}

pub fn run_world_collisons(self:PlayerState(cs),world_boxes:List(Collider(cs))) {
  let frame = get_current_frame(self)
  use player,col <- list.fold(world_boxes,self)
  let assert WorldBox(box,on_col) = col

  let box_body = basics.RiggdBody(vector2.Vector2(0.0,0.0),vector2.Vector2(0.0,0.0))
  case collisons.moving_box_collision(frame.world_box.box,player.body,box,box_body) {
    Error(err) -> {
      //todo only update on the floor colider
      PlayerState(..player,grounded:False)
    }
    Ok(point) -> {
        // let col = box |> echo
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
