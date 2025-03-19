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

pub fn main() {
  io.println("Hello from game")
  raylib.init_window(600,400,"please work")
  raylib.set_target_fps(60)
  let test_texture = raylib.load_texture("./assets/Sprite-0001.png") |> io.debug
  kernel.new_game_kernel()
  |> kernel.update_p1_input_map(default_input_map_p1())
  |> kernel.update_p1_attack_map(default_attack_map_p1())
  |> update()
  raylib.unload_texture(test_texture)
  raylib.close_window()
}

//todo limit to 60 fps
fn update(game_engine:kernel.GameKernel) {

  raylib.begin_drawing()
  case raylib.should_windows_close() {
    False -> {
      raylib.clear_background()

      let game_engine = get_pressed_keys(game_engine.p1.used_keys)
      |> kernel.input_p1(game_engine,_)
      |> kernel.pick_state_p1
      //raylib.draw_texture(game_state,300.0,200.0)
      raylib.end_drawing()
      update(game_engine)
    }
    True -> {
      raylib.end_drawing()
      game_engine
    }
  }
}

pub fn get_pressed_keys(input_map:List(input.Key)) -> List(input.Key){
  use key <- list.filter_map(input_map)
  case raylib.is_key_down(key) {
    True -> Ok(key)
    False -> Error(Nil)
  }
}
