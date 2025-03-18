import gleam/bool
import gleam/io
import birl
import raylib
pub fn main() {
  io.println("Hello from renderer!")
  raylib.init_window(400,600,"please work")
  raylib.set_target_fps(60)
  update(Nil)
  raylib.close_window()
}

//todo limit to 60 fps
fn update(game_state) {
  raylib.begin_drawing()
  case raylib.should_windows_close() {
    False -> {
      raylib.get_char_pressed()

      raylib.end_drawing()
      update(game_state)
    }
    True -> {
      raylib.end_drawing()
      game_state
    }
  }
}
