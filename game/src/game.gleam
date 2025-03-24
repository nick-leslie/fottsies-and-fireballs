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

pub type GameState{
  GameState(
    kernel:kernel.GameKernel,
    texture_map:dict.Dict(Int,iv.Array(raylib.Texture))
  )
}
pub fn main() {
  io.println("Hello from game")
  raylib.init_window(800,600,"please work")
  raylib.set_target_fps(60)
  let test_texture = raylib.load_texture("./assets/Sprite-0001.png") |> io.debug
  let game_kernel = kernel.new_game_kernel()
  |> kernel.update_p1_input_map(default_input_map_p1())
  |> kernel.update_p1_attack_map(default_attack_map_p1())

  let texture_map = dict.new()
  |> dict.insert(0,iv.from_list([test_texture]))
  update(GameState(game_kernel,texture_map))
  raylib.unload_texture(test_texture)
  raylib.close_window()
}

//todo limit to 60 fps
fn update(game_engine:GameState) {

  raylib.begin_drawing()
  case raylib.should_windows_close() {
    False -> {
      raylib.clear_background()

      let game_kernel =
      get_pressed_keys(game_engine.kernel.p1_controls.used_keys)
      |> kernel.input_p1(game_engine.kernel,_)
      |> kernel.run_frame()
      let cam = raylib.Camera(
        raylib.Vector2(800.0 /. 2.0,600.0 /. 2.0),
        raylib.Vector2(game_kernel.p1.x,game_kernel.p1.y),
        0.0,
        1.0
      )
      raylib.begin_mode_2d(cam)
        //draw phase
        let _ = draw_player(game_kernel.p1,game_engine.texture_map)
        draw_world(game_kernel)
        raylib.draw_line(0.0,1000.0,0.0,-1000.0)
        game_kernel.p1
        |> draw_collider()
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

fn draw_player(player:player.PlayerState,texture_map:dict.Dict(Int,iv.Array(raylib.Texture))) {
  use frame_textures <- result.try(dict.get(texture_map,player.current_state))
  use texture <- result.try(iv.get(frame_textures,player.current_frame))
  Ok(raylib.draw_texture(texture,player.x -. texture.width /. 2.0,player.y -. texture.height /. 2.0))
}

fn draw_vel(player:player.PlayerState) {
  let frame = player.get_current_frame(player)
  let player_box_rect= player.collider_to_player_space(player,frame.world_box.box)

  let start = #(player_box_rect.x,player_box_rect.y +. player_box_rect.height)
  let end = #(player_box_rect.x +. player.velocity.0,{player_box_rect.y +. player_box_rect.height } +. player.velocity.1)
  raylib.draw_line(start.0,start.1,end.0,end.1)
  player
}

fn draw_collider(player:player.PlayerState) {
  let frame = player.get_current_frame(player)
  let col = player.collider_to_player_space(player,frame.world_box.box)
  raylib.draw_rectangle_rect(col)
  player
}


fn draw_world(kernel:kernel.GameKernel) {
  use col <- list.each(kernel.world_colliders)
  raylib.draw_rectangle_rect(col.box)
}

pub fn get_pressed_keys(input_map:List(input.Key)) -> List(input.Key){
  use key <- list.filter_map(input_map)
  case raylib.is_key_down(key) {
    True -> Ok(key)
    False -> Error(Nil)
  }
}
