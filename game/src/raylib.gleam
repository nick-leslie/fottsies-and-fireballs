@external(javascript, "./raylib_ffi.mjs", "init_window")
pub fn init_window(width:Int,heigth:Int,title:String) -> Nil

@external(javascript, "./raylib_ffi.mjs", "set_target_fps")
pub fn set_target_fps(fps:Int) -> Nil

@external(javascript, "./raylib_ffi.mjs", "should_windows_close")
pub fn should_windows_close() -> Bool

@external(javascript, "./raylib_ffi.mjs", "close_window")
pub fn close_window() -> Nil

@external(javascript, "./raylib_ffi.mjs", "get_char_pressed")
pub fn get_char_pressed() -> Int

@external(javascript, "./raylib_ffi.mjs", "begin_drawing")
pub fn begin_drawing() -> Nil

@external(javascript, "./raylib_ffi.mjs", "clear_background")
pub fn clear_background() -> Nil

@external(javascript, "./raylib_ffi.mjs", "end_drawing")
pub fn end_drawing() -> Nil


// textures ------------------

pub type Texture
@external(javascript, "./raylib_ffi.mjs", "load_texture")
pub fn load_texture(path:String) -> Texture

@external(javascript, "./raylib_ffi.mjs", "unload_texture")
pub fn draw_texture(texture:Texture) -> Nil

@external(javascript, "./raylib_ffi.mjs", "unload_texture")
pub fn unload_texture(texture:Texture) -> Nil
