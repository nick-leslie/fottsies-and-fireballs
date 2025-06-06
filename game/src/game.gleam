import bun
import gleam/javascript/promise
import gleam/int
import birl/duration
import iv
import player
import gleam/result
import gleam/option
import gleam/list
import gleam/bool
import gleam/io
import gleam/dict
import birl
import raylib
import game_kernel as kernel
import input

pub const key_w = 87
pub const key_a = 65
pub const key_s = 83
pub const key_d = 68

pub const key_j = 74
pub const key_k = 75
pub const key_l = 76

pub const key_p = 80 //pause
pub const key_n = 78 // step simulation

fn default_input_map_p1() {
  dict.new()
  |> dict.insert(key_w,input.Up)
  |> dict.insert(key_a,input.Back)
  |> dict.insert(key_s,input.Down)
  |> dict.insert(key_d,input.Forward)
}
fn default_attack_map_p1() {
  dict.new()
  |> dict.insert(key_j,input.Light)
  |> dict.insert(key_k,input.Medium)
  |> dict.insert(key_l,input.Heavy)
}
pub type Charecters{
  FreddyFireball()
}

pub type GameState{
  GameState(
    kernel:kernel.GameKernel(Charecters),
    p1_sheet:raylib.Texture,
    p2_sheet:raylib.Texture,
    paused:Bool,
  )
}


const sprite_scale = 4.0
const cam_zoom = 0.50
pub fn main() {
  io.println("Hello from game")
  raylib.init_window(800,600,"please work")
  raylib.set_target_fps(60)
  let p1_texture = raylib.load_texture("./assets/sheet.png")
  let game_kernel = kernel.new_game_kernel(sprite_scale,FreddyFireball,FreddyFireball)
  |> kernel.update_p1_input_map(default_input_map_p1())
  |> kernel.update_p1_attack_map(default_attack_map_p1())


  update(GameState(game_kernel,p1_texture,p1_texture,False))
  raylib.unload_texture(p1_texture)
  raylib.close_window()
  // promise.tap(bun.generate_heap_snapshot(),fn (a) {a})
  bun.heap_stats()
}

fn game_update(game_engine:GameState) {
  get_pressed_keys(game_engine.kernel.p1_controls.used_keys)
  |> kernel.input_p1(game_engine.kernel,_)
  |> kernel.run_frame()
}

//todo limit to 60 fps
fn update(game_engine:GameState) {

  raylib.begin_drawing()
  raylib.draw_fps(10.0,10.0)
  case raylib.should_windows_close() {
    False -> {
      raylib.clear_background()
      let game_engine = case raylib.is_key_pressed(key_p) {
        False -> game_engine
        True -> GameState(..game_engine,paused:!game_engine.paused)
      }
      let cam = raylib.Camera(
        raylib.Vector2(800.0 /. 2.0,600.0 /. 2.0),
        raylib.Vector2(game_engine.kernel.p1.body.pos.x,game_engine.kernel.p1.body.pos.y),
        0.0,
        cam_zoom
      )
      raylib.begin_mode_2d(cam)
       let game_kernel = case game_engine.paused {
        False -> {
          let start = birl.now()
          let game = game_update(game_engine)
          birl.difference(birl.now(),start)
          |> duration.accurate_decompose
          // |> echo
          game
        }
        True -> case raylib.is_key_down(key_n) {
          True -> game_update(game_engine)
          False -> game_engine.kernel
        }
      }

      //draw phase
      let _ = draw_player(game_kernel.p1,game_engine.p1_sheet)
      draw_world(game_kernel)
      raylib.draw_line(0.0,1000.0,0.0,-1000.0)
      game_kernel.p1
      |> draw_collider()
      |> draw_hitboxs()
      // |> draw_hurtboxs()
      |> draw_vel()
      let _ = draw_player(game_kernel.p2,game_engine.p2_sheet)

      game_kernel.p2
      |> draw_collider()
      |> draw_hitboxs()
      // |> draw_hurtboxs()
      |> draw_vel()

      raylib.end_mode_2d(cam)
      raylib.end_drawing()
      update(GameState(..game_engine,kernel:game_kernel))
    }
    True -> {
      raylib.end_drawing()
      game_engine
    }
  }

}

const sprite_size = 32.0

fn draw_player(player:player.PlayerState(cs),texture:raylib.Texture) {
  Ok(raylib.draw_texture_pro(
    texture:texture,
    source:raylib.Rectangle(
      sprite_size *. player.p1_side,
      sprite_size,
      0.0 +. {sprite_size *. int.to_float(player.current_frame)},
      0.0 +. {sprite_size *. int.to_float(player.current_state)}
    ),
    dest:raylib.Rectangle(
      sprite_size *. sprite_scale,
      sprite_size *. sprite_scale,
      {player.body.pos.x -. { {sprite_size *. sprite_scale}  /. 2.0} },
      {player.body.pos.y -. {{sprite_size *. sprite_scale} /. 2.0} }
    ),
    x: 0.0,
    y: 0.0,
    rot:0.0,
    tint:raylib.ray_white
  ))
}

fn draw_vel(player:player.PlayerState(cs)) {
  let frame = player.get_current_frame(player)
  let player_box_rect= player.collider_to_player_space(player,frame.world_box.box)

  let start = #(player_box_rect.x,player_box_rect.y +. player_box_rect.height)
  let end = #(player_box_rect.x +. player.body.vel.x,{player_box_rect.y +. player_box_rect.height } +. player.body.vel.y)
  raylib.draw_line(start.0,start.1,end.0,end.1)
  player
}

fn draw_collider(player:player.PlayerState(cs)) {
  let frame = player.get_current_frame(player)
  let col = player.collider_to_player_space(player,frame.world_box.box)
  //this is because math is centered but render is right allighend
  // raylib.draw_rectangle_rect(col |> echo)
  raylib.draw_rectangle(col.x-.{col.width /. 2.0},col.y-.{col.height /. 2.0},col.width,col.height,raylib.ray_blue)
  player
}

pub fn draw_hitboxs(player:player.PlayerState(cs)) {
  let frame = player.get_current_frame(player)
  case frame {
    player.Active(_, _, _, _, hit_boxes) -> {
      {
        use hit_box <- list.map(hit_boxes)
        let col = player.collider_to_player_space(player,hit_box.box)
        //this is because math is centered but render is right allighend
        // raylib.draw_rectangle_rect(col |> echo)
        raylib.draw_rectangle(col.x-.{col.width /. 2.0},col.y-.{col.height /. 2.0},col.width,col.height,raylib.red)
      }
      player
    }
    _ -> player
  }
}
pub fn draw_hurtboxs(player:player.PlayerState(cs)) {
  let frame = player.get_current_frame(player)
  {
    use hit_box <- list.map(frame.hurt_boxes)
    let col = player.collider_to_player_space(player,hit_box.box)
    //this is because math is centered but render is right allighend
    // raylib.draw_rectangle_rect(col |> echo)
    raylib.draw_rectangle(col.x-.{col.width /. 2.0},col.y-.{col.height /. 2.0},col.width,col.height,raylib.green)
  }
  player
}

fn draw_world(kernel:kernel.GameKernel(cs)) {
  use col <- list.each(kernel.world_colliders)
  raylib.draw_rectangle(col.box.x-.{col.box.width /. 2.0},col.box.y-.{col.box.height /. 2.0},col.box.width,col.box.height,raylib.ray_blue)
}

pub fn get_pressed_keys(input_map:List(input.Key)) -> List(input.Key){
  use key <- list.filter_map(input_map)
  case raylib.is_key_down(key) {
    True -> Ok(key)
    False -> Error(Nil)
  }
}
