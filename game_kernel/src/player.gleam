import gleam/dict
import gleam/order
import gleam/io
import gleam/option
import iv
import input.{Input,Up,Down,DownForward,Forward,InputWithAttack,Light,Neutral,Back}
import gleam/list
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
pub type PlayerState(charecter_extras) {
  PlayerState(
    p1_side:Float,
    body: basics.RiggdBody,
    states:dict.Dict(Int,State(charecter_extras)),//todo we may  want to use dicts for this
    patterns:List(input.Pattern),
    current_state:Int,
    current_frame:Int,
    blocking:Bool,
    grounded:Bool,
    charge:Int,
    charecter_extras:charecter_extras //todo rename this
  )
}

pub fn new_player(side p1_side:Float,x x,y y,charecter_extras charecter_extras:charecter_extras) -> PlayerState(charecter_extras) {
  PlayerState(
    p1_side:p1_side,
    body:basics.new(vector2.Vector2(x,y),10.0),
    states:dict.new(), //todo replace with editor stuff
    patterns:list.new(),
    current_state:0,
    current_frame:0,
    blocking:False,
    grounded:False,
    charge:0,
    charecter_extras:charecter_extras
  )
}
//todo pull this out and make it editor stuff
pub fn inital_states(player:PlayerState(charecter_extras),scale) {
  let player_col = make_player_world_box(xy:#(0.0 *. scale,20.0 *.scale),wh:#(50.0 *. scale,10.0*. scale))
  let hurtbox = HurtBox(Rectangle(32.0 *. scale,32.0 *. scale,0.0,0.0))
  let states = [
    State("neutral",iv.from_list([
    Active(hit_boxes:[],world_box:player_col,hurt_boxes:[hurtbox],cancel_options:[],on_frame:option.
      Some(fn(player) {
        PlayerState(..player,body: basics.RiggdBody(..player.body,vel:vector2.Vector2(0.0,player.body.vel.y)))
      })
    )
  ])),
  State("forward",iv.from_list([
    Active(hit_boxes:[],world_box:player_col,hurt_boxes:[hurtbox],cancel_options:[],on_frame:option.
      Some(fn(player) {
        PlayerState(..player,body: basics.RiggdBody(..player.body,vel:vector2.add(player.body.vel,vector2.Vector2(5.0 *. player.p1_side,0.0))))
      })
    )
  ])),
  State("backward",iv.from_list([
    Active(hit_boxes:[],world_box:player_col,hurt_boxes:[hurtbox],cancel_options:[],on_frame:option.
      Some(fn(player) {
        PlayerState(..player,body: basics.RiggdBody(..player.body,vel:vector2.add(player.body.vel,vector2.Vector2(-5.0 *. player.p1_side,0.0))))
      })
    )
  ])),
  State("up",iv.from_list(list.flatten([
    Active(hit_boxes:[],world_box:player_col,hurt_boxes:[hurtbox],cancel_options:[],on_frame:option.
      Some(fn(player:PlayerState(charecter_extras)) {
        //todo add a grounded state to players
        PlayerState(..player,
          body: basics.add_force(player.body,vector2.Vector2(0.0,-17.0))
      )}
    )) |> list.repeat(20),
    Recovery([],player_col,[],option.None) |> list.repeat(40)
  ]))),
  State("upbackward",iv.from_list(list.flatten([
    [Active(hit_boxes:[],world_box:player_col,hurt_boxes:[hurtbox],cancel_options:[],on_frame:option.
      Some(fn(player) {
        PlayerState(..player,
          body: basics.add_force(player.body,vector2.Vector2(-40.0*. player.p1_side,-230.0))
        )
      })
    )],
    Recovery([],player_col,[],option.None) |> list.repeat(60)
  ]))),
  State("upforward",iv.from_list(list.flatten([
    [Active(hit_boxes:[],world_box:player_col,hurt_boxes:[hurtbox],cancel_options:[],on_frame:option.
      Some(fn(player) {
        PlayerState(..player,
          body: basics.add_force(player.body,vector2.Vector2(40.0*. player.p1_side,-230.0))
        )
      })
    )],
    Recovery([],player_col,[],option.None) |> list.repeat(60)
  ]))),
  ]
  |> list.index_fold(player.states,fn(states,state,index) {dict.insert(states,index,state)})

  states |> dict.keys() |> echo

  PlayerState(
    ..player,
    states: states
  )
  |> add_new_pattern(input:[Input(Neutral)],state_index: 0, priority:0)
  |> add_new_pattern(input:[Input(Forward)], state_index:1,priority:0)
  |> add_new_pattern(input:[Input(Back)], state_index:2,priority:0)
  |> add_new_pattern(input:[Input(Up)], state_index:3,priority:0)
  |> add_new_pattern(input:[Input(input.UpBack)], state_index:4,priority:0)
  |> add_new_pattern(input:[Input(input.UpForward)], state_index:5,priority:0)
}

pub fn append_states(player:PlayerState(charecter_extras),states:List(State(charecter_extras))) {
  let states = list.fold(states,player.states,fn(states,state) {dict.insert(states,dict.size(states),state)})
  states |> dict.keys |> echo
  PlayerState(
    ..player,
    states: states
  )
}


pub fn add_new_pattern(player:PlayerState(ce),input input:List(input.Input),state_index state_index:StateIndex,priority priority:Int) {
  //this is slower but its a one time thing and its needed for priority
  let patterns  = list.append(player.patterns,[input.Pattern(
    input,
    state_index,
    priority,
    option.None
  )])
  PlayerState(..player,patterns:patterns)
}


pub fn get_current_frame(player:PlayerState(ce)) {
  let assert Ok(player_state) = dict.get(player.states,player.current_state)
  let assert Ok(player_frame) = iv.get(player_state.frames,player.current_frame)
  player_frame
}


//---- states

pub type State(charecter_extras) {
  State(
    name:String,
    frames:iv.Array(Frame(charecter_extras))
  )
}



pub type Frame(charecter_extras) {
  Startup(
    hurt_boxes:List(Collider(charecter_extras)),
    world_box:Collider(charecter_extras),
    cancel_options:List(StateIndex),
    on_frame:option.Option(fn (PlayerState(charecter_extras)) -> PlayerState(charecter_extras)),
  )
  Active (
    hurt_boxes:List(Collider(charecter_extras)),
    world_box:Collider(charecter_extras),
    cancel_options:List(StateIndex),
    on_frame:option.Option(fn (PlayerState(charecter_extras)) -> PlayerState(charecter_extras)),
    hit_boxes:List(Collider(charecter_extras)),
  )
  Recovery(
    hurt_boxes:List(Collider(charecter_extras)),
    world_box:Collider(charecter_extras),
    cancel_options:List(StateIndex),
    on_frame:option.Option(fn (PlayerState(charecter_extras)) -> PlayerState(charecter_extras)),
  )
  Stun(
    hurt_boxes:List(Collider(charecter_extras)),
    world_box:Collider(charecter_extras),
    cancel_options:List(StateIndex),
    on_frame:option.Option(fn (PlayerState(charecter_extras)) -> PlayerState(charecter_extras)),
    is_hitstun:Bool
  )
}

pub fn update_state(player:PlayerState(ce),buffer:input.Buffer) {
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


pub fn add_grav(player:PlayerState(ce)) {
  //todo we may want to disable grav
  // case player.body.vel.y <. grav_max {
  //   True -> PlayerState(..player,body:
  //     basics.RiggdBody(..player.body,vel:vector2.add(player.body.vel,vector2.Vector2(0.0,grav_max)
  //     )))
  //   False -> {
  //     PlayerState(..player,body:
  //       basics.RiggdBody(..player.body,vel:vector2.Vector2(player.body.vel.x,10.0)
  //       ))
  //   }
  // }
  PlayerState(
    ..player,
    body:basics.add_force(player.body,vector2.Vector2(0.0,9.8))
  )
}

//todo this is breaking
fn advance_frame(player:PlayerState(ce),next_state:StateIndex) {
  let assert Ok(state) = dict.get(player.states,player.current_state)
  case {player.current_frame == {iv.length(state.frames) - 1}} {
    False -> {
      PlayerState(..player,current_frame:player.current_frame+1)
    }
    True -> {
      PlayerState(..player,current_state:next_state,current_frame:0)
    }
  }
}

fn run_frame(player:PlayerState(ce)) {
  //todo resolve collisons and physics here
  let current_frame = get_current_frame(player)
  case current_frame.on_frame {
    option.None -> player
    option.Some(on_frame) -> on_frame(player)
  }
}
//todo fix me
pub fn check_side(self:PlayerState(ce),other:PlayerState(ce)) {
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


pub fn step(player:PlayerState(ce)) {

  PlayerState(..player,
    body:basics.step(player.body)
    |> basics.move_by_vel
  )
}

//--- collisions
type OnCollionFn(ce) = fn (#(Float,Float),PlayerState(ce)) -> PlayerState(ce)

pub fn no_mod_col(vec:#(Float,Float),ps:PlayerState(ce)) {
  ps
}

pub type Collider(ce) {
  Hitbox(
    box:Rectangle,
    hit_stun_frames:Int,
    hit_stun_fn:OnCollionFn(ce), // todo refactor
    block_stun_frames:Int,
    block_stun_fn:OnCollionFn(ce)
  )
  HurtBox(
    box:Rectangle
  )
  WorldBox(
    box:Rectangle,
    on_colison:OnCollionFn(ce),
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




pub type CollionInfo(ce) {
  HurtCollion(
    col:Collider(ce),
    moddify_vel:OnCollionFn(ce),
    stun_frames:Int,
    state_index:Int
  )
  PlayerToWorld(
    player:PlayerState(ce),
    moddify_vel:OnCollionFn(ce),
  )
}

pub fn collider_to_player_space(player:PlayerState(ce),box:Rectangle) {
  Rectangle(..box,x:box.x +. player.body.pos.x,y:box.y +. player.body.pos.y)
}

pub fn run_world_collisons(self:PlayerState(ce),world_boxes:List(Collider(ce))) {
  let frame = get_current_frame(self)
  use player,col <- list.fold(world_boxes,self)
  let assert WorldBox(box,on_col) = col

  let box_body = basics.new(vector2.Vector2(0.0,0.0),10.)
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

//could be a message buss
//todo plan to flatten this with assert
//tood bug were we are collidign with self
pub fn get_hurt_collisons(self,other) ->  List(CollionInfo(ce)) {
  let self_frame = get_current_frame(self)
  let other_frame = get_current_frame(other)
  //check if the other player is active and check if there hit boxes overlap with our hurt boxes
  case other_frame {
    Active(_hurt_boxs,_world_box,_cancle_options, _on_active, hit_boxs) -> {
      //if any resolve as  collision we return
      use colided_list,hit_box <- list.fold(hit_boxs,[])
      let assert Hitbox(hit_rect,hit_stun_frames,hit_stun_fn,block_stun_frames,block_stun_fn) = hit_box

      use colided_list,hurt_box <- list.fold(self_frame.hurt_boxes,colided_list)
      // todo check perf
      case collisons.moving_box_collision(hit_rect,other.body,hurt_box.box,self.body) {
        Ok(_point) -> {
          list.append(colided_list,[
            case self.blocking {
              True ->   HurtCollion(hurt_box,block_stun_fn,block_stun_frames,0) //todo update index to be correct based on state
              False ->  HurtCollion(hurt_box,hit_stun_fn,hit_stun_frames,0)
            }
          ])
        }
        Error(_any) -> {
          colided_list
        }
      }
    }
    _ -> []
  }
}

//todo I need to come up with rules for how to decide what state index to apply.
pub fn resolve_collison_state(col_list:List(CollionInfo(ce)),player:PlayerState(ce))  {
  use player,col_info <- list.fold(col_list,player)
  let assert HurtCollion(_colider,apply_force,_stun_frames,_state_index) = col_info
  apply_force(#(0.0,0.0),player) //todo for now this works
}

//todo may want to seprate this into primatives but like for now we chillen
