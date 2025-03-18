import gleam/bool
import gleam/io
import birl

pub fn main() {
  io.println("Hello from renderer!")
  init_window(400,600,"please work")
  set_target_fps(60)
  update(Nil)
  close_window()
}

//todo limit to 60 fps
fn update(game_state) {
  begin_drawing()
  case should_windows_close() {
    False -> {
      get_char_pressed()

      end_drawing()
      update(game_state)
    }
    True -> {
      end_drawing()
      game_state
    }
  }
}


@external(javascript, "./raylib_ffi.mjs", "init_window")
fn init_window(width:Int,heigth:Int,title:String) -> Nil

@external(javascript, "./raylib_ffi.mjs", "set_target_fps")
fn set_target_fps(fps:Int) -> Nil

@external(javascript, "./raylib_ffi.mjs", "should_windows_close")
fn should_windows_close() -> Bool

@external(javascript, "./raylib_ffi.mjs", "close_window")
fn close_window() -> Nil

@external(javascript, "./raylib_ffi.mjs", "get_char_pressed")
fn get_char_pressed() -> Int

@external(javascript, "./raylib_ffi.mjs", "begin_drawing")
fn begin_drawing() -> Nil

@external(javascript, "./raylib_ffi.mjs", "clear_background")
fn clear_background() -> Nil

@external(javascript, "./raylib_ffi.mjs", "end_drawing")
fn end_drawing() -> Nil
