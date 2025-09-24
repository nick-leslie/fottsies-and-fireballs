import gleam/bool
import gleam/dict
import gleam/float
import gleam/io
import gleam/list
import gleam/option
import gleam/order
import input
import iv
import physics/riggdbody
import physics/collisons
import physics/vector2
import raylib.{type Rectangle, Rectangle}

//todo if things get nasty then we do this
const grav_max = 1.1

const full_screen_max = 100

// this is the maximum distence that we are able to walk from the other player

type StateIndex =
  Int

pub type PlayerStats(extra_stats,extra_state) {
  PlayerStats(
    //this is realy closer to states but state is an overloaded term
    moves: dict.Dict(Int, Move(extra_state)),
    patterns: List(input.Pattern),
    max_health: Int,
    walk_speed:Float,
    air_speed:Float, // this is the speed of forward and backward jumps
    mass:Float,
    charecter_extras: extra_stats,
  )
}

pub fn new_player_stats(
  max_health: Int,
  walk_speed:Float,
  air_speed:Float, // this is the speed of forward and backward jumps
  mass:Float,
  charecter_extras: extra_stats,
) -> PlayerStats(extra_stats,extra_state) {
  PlayerStats(
    moves: dict.new(),
    patterns: [],
    max_health: max_health,
    walk_speed: walk_speed,
    air_speed: air_speed,
    mass: mass,
    charecter_extras: charecter_extras,
  )
}

pub type PlayerState(extra_state) {
  PlayerState(
    p1_side: Float,
    body: riggdbody.RiggdBody,
    current_state: Int,
    current_frame: Int,
    blocking: Bool,
    grounded: Bool,
    charge: Int,
    hit_stun: Int,
    health:Int,
    extra:extra_state
  )
}
pub type ExtraStatsInit(extra_stats,extra_state) = fn(PlayerStats(extra_stats,extra_state)) -> extra_state

//we call it extra because this is stats that are dif per charecter

//todo we may ned to split this up to reduce the copying
// right now we have player taking the world as a generic so we can do things like spawn fireballs

pub fn new_player_state(
  stats stats:PlayerStats(extra_stats,extra_state),
  extra_state_init extra_state_init:ExtraStatsInit(extra_stats,extra_state),
  side side:Float,
  start_pos start_pos:vector2.Vector2) -> PlayerState(extra_state) {
    PlayerState(
      p1_side:side,
      body:riggdbody.new(start_pos,stats.mass),
      current_frame:0,
      current_state:0,
      grounded:True,
      blocking:False,
      charge:0,
      hit_stun:0,
      health:stats.max_health,
      extra:extra_state_init(stats)
    )
}

pub fn append_moves(
  player: PlayerStats(extra_stats,extra_state),
  moves: List(Move(extra_state)),
) {
  let moves =
    list.fold(moves, player.moves, fn(moves, move) {
      dict.insert(moves, dict.size(moves), move)
    })
  moves |> dict.keys |> echo
  PlayerStats(..player, moves: moves)
}

pub fn add_new_pattern(
  player: PlayerStats(extra_stats,extra_state),
  input input: List(input.Input),
  state_index state_index: StateIndex,
  priority priority: Int,
) {
  //this is slower but its a one time thing and its needed for priority
  let patterns =
    list.append(player.patterns, [
      input.Pattern(input, state_index, priority, option.None),
    ])
  PlayerStats(..player, patterns: patterns)
}

pub fn get_current_frame(stats stats:PlayerStats(extra_stats,extra_state),state state:PlayerState(extra_state)) -> Frame(extra_state) {
  let assert Ok(player_state) = dict.get(stats.moves, state.current_state)
  let assert Ok(player_frame) =
    iv.get(player_state.frames, state.current_frame)
  player_frame
}

//---- states

pub type Move(extra_state) {
  Move(name: String, frames: iv.Array(Frame(extra_state)))
}

pub type Frame(extra_state) {
  Startup(
    hurt_boxes: List(Collider(extra_state)),
    world_box: Collider(extra_state),
    cancel_options: List(StateIndex),
    on_frame: option.Option(
      fn(PlayerState(extra_state)) -> PlayerState(extra_state),
    ),
  )
  Active(
    hurt_boxes: List(Collider(extra_state)),
    world_box: Collider(extra_state),
    cancel_options: List(StateIndex),
    on_frame: option.Option(
      fn(PlayerState(extra_state)) -> PlayerState(extra_state),
    ),
    hit_boxes: List(Collider(extra_state)),
  )
  Recovery(
    hurt_boxes: List(Collider(extra_state)),
    world_box: Collider(extra_state),
    cancel_options: List(StateIndex),
    on_frame: option.Option(
      fn(PlayerState(extra_state)) -> PlayerState(extra_state),
    ),
  )
  Stun(
    hurt_boxes: List(Collider(extra_state)),
    world_box: Collider(extra_state),
    cancel_options: List(StateIndex),
    on_frame: option.Option(
      fn(PlayerState(extra_state)) -> PlayerState(extra_state),
    ),
    is_hitstun: Bool,
  )
}

pub fn update_state(player_state player_state:PlayerState(extra_state),player_stats player_stats:PlayerStats(extra_stats,extra_state),buffer buffer: input.Buffer) -> PlayerState(extra_state) {
  let proposed_state = input.pick_state(buffer, player_stats.patterns)
  case proposed_state == player_state.current_state {
    False -> {
      let frame = get_current_frame(stats:player_stats,state:player_state)
      case
        list.find(frame.cancel_options, fn(cancel_index) {
          cancel_index == proposed_state
        })
      {
        Error(_) -> {
          advance_frame(player_state,player_stats, proposed_state)
        }
        Ok(_) -> {
          PlayerState(..player_state, current_state: proposed_state, current_frame: 0)
        }
      }
    }
    True -> {
      advance_frame(player_state,player_stats, 0)
    }
  }
  |> run_frame(player_stats)
}

pub fn add_grav(player: PlayerState(extra_state)) {
  PlayerState(
    ..player,
    body: riggdbody.add_force(player.body, vector2.Vector2(0.0, grav_max)),
  )
}

//todo this is breaking
fn advance_frame(player_state: PlayerState(extra_state),player_stats:PlayerStats(extra_stats,extra_state), next_state: StateIndex) {
  let assert Ok(state) = dict.get(player_stats.moves, player_state.current_state)
  use <- bool.guard(
    player_state.hit_stun > 0,
    PlayerState(..player_state, hit_stun: player_state.hit_stun - 1),
  )
  // if we dont have hitstun increase current frame
  use <- bool.guard(
    { player_state.current_frame == { iv.length(state.frames) - 1 } },
    PlayerState(..player_state, current_state: next_state, current_frame: 0),
  )
  // reset if we reach endr
  PlayerState(..player_state, current_frame: player_state.current_frame + 1)
}

fn run_frame(state:PlayerState(extra_state),stats:PlayerStats(extra_stats,extra_state)) {
  let current_frame = get_current_frame(stats,state)
  //todo resolve collisons and physics here
  case current_frame.on_frame {
    option.None -> state
    option.Some(on_frame) -> on_frame(state)
  }
}

//todo fix me
pub fn check_side(self: PlayerState(extra_state), other: PlayerState(extra_state2)) {
  let self_body = self.body |> riggdbody.move_by(self.body.vel)
  let other_body = other.body |> riggdbody.move_by(self.body.vel)
  case float.compare(self_body.pos.x -. other_body.pos.x, 0.0) {
    order.Eq -> PlayerState(..self, body: self_body, p1_side: 1.0)
    order.Gt -> PlayerState(..self, p1_side: -1.0)
    order.Lt -> PlayerState(..self, p1_side: 1.0)
  }
}

// ---- physics
//

pub fn step(player: PlayerState(extra_state)) {
  PlayerState(
    ..player,
    body: riggdbody.step(player.body)
      |> riggdbody.move_by_vel,
  )
}

//--- collisions
type OnCollionFn(extra_state) =
  fn(#(Float, Float), PlayerState(extra_state)) -> PlayerState(extra_state)

pub fn no_mod_col(_vec: #(Float, Float), ps: PlayerState(extra_state)) {
  ps
}

pub type Collider(extra_state) {
  Hitbox(
    box: Rectangle,
    dmg: Int,
    hit_stun_frames: Int,
    hit_stun_fn: OnCollionFn(extra_state),
    // todo refactor
    block_stun_frames: Int,
    block_stun_fn: OnCollionFn(extra_state),
  )
  HurtBox(box: Rectangle)
  WorldBox(
    box: Rectangle,
    on_colison: OnCollionFn(extra_state),
    //no_col_err: this is for the error we emit when there is no collison sould wrap a collsion error and another error
  )
}

pub fn make_player_world_box(wh wh: #(Float, Float), xy xy: #(Float, Float)) {
  WorldBox(
    Rectangle(width: wh.0, height: wh.1, x: xy.0, y: xy.1),
    fn(_point, player) {
      io.debug("gaming")
      player
    },
  )
  // todo this might be bad ish
}

pub type CollionInfo(extra_state) {
  HurtCollion(
    col: Collider(extra_state),
    moddify_vel: OnCollionFn(extra_state),
    stun_frames: Int,
    state_index: Int,
  )
  PlayerToWorld(player: PlayerState(extra_state), moddify_vel: OnCollionFn(extra_state))
}

pub fn collider_to_player_space(player: PlayerState(ce), box: Rectangle) {
  Rectangle(..box, x: box.x +. player.body.pos.x, y: box.y +. player.body.pos.y)
}

pub fn run_world_collisons(
  state state: PlayerState(extra_state),
  stats stats:PlayerStats(extra_stats,extra_state),
  world_boxes world_boxes: List(Collider(extra_state)),
) {
  let frame = get_current_frame(stats,state)
  use player, col <- list.fold(world_boxes, state)
  let assert WorldBox(box, on_col) = col
  let box_body = riggdbody.new(vector2.Vector2(0.0, 0.0), 10.0)
  case
    //todo what do we do here
    collisons.moving_box_collision(
      frame.world_box.box,
      player.body,
      box,
      box_body,
    )
  {
    Error(err) -> {
      //todo only update on the floor colider
      PlayerState(..player, grounded: False)
    }
    Ok(point) -> {
      on_col(vector2.to_tuple(point), player)
    }
  }
}

//could be a message buss
//todo plan to flatten this with assert
//tood bug were we are collidign with self
//todo should be able to apply knockback to self. rework to return both players
pub fn get_hurt_collisons(
  self_state:PlayerState(extra_state),
  self_stats:PlayerStats(extra_stats,extra_state),
  other_state:PlayerState(extra_state),
  other_stats:PlayerStats(extra_stats,extra_state)) -> List(CollionInfo(extra_state)) {
  let self_frame = get_current_frame(state:self_state,stats:self_stats)
  let other_frame = get_current_frame(state:other_state,stats:other_stats)
  //check if the other player is active and check if there hit boxes overlap with our hurt boxes
  case other_frame {
    Active(_hurt_boxs, _world_box, _cancle_options, _on_active, hit_boxs) -> {
      //if any resolve as  collision we return
      use colided_list, hit_box <- list.fold(hit_boxs, [])
      let assert Hitbox(
        hit_rect,
        damage,
        hit_stun_frames,
        hit_stun_fn,
        block_stun_frames,
        block_stun_fn,
      ) = hit_box

      use colided_list, hurt_box <- list.fold(
        self_frame.hurt_boxes,
        colided_list,
      )
      // todo check perf
      // todo this is a bug wth collison
      case
        collisons.moving_box_collision(
          hit_rect,
          other_state.body,
          hurt_box.box,
          self_state.body,
        )
      {
        Ok(_point) -> {
          list.append(colided_list, [
            case self_state.blocking {
              True -> HurtCollion(hurt_box, block_stun_fn, block_stun_frames, 0)
              //todo update index to be correct based on state
              False -> HurtCollion(hurt_box, hit_stun_fn, hit_stun_frames, 0)
            },
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
pub fn resolve_collison_state(
  col_list: List(CollionInfo(ce)),
  player: PlayerState(ce),
) {
  use player, col_info <- list.fold(col_list, player)
  let assert HurtCollion(_colider, apply_force, stun_frames, state_index) =
    col_info
  PlayerState(
    ..{ apply_force(#(0.0, 0.0), player) },
    hit_stun: stun_frames,
    current_state: state_index,
  )
  //todo for now this works
}
//todo may want to seprate this into primatives but like for now we chillen
