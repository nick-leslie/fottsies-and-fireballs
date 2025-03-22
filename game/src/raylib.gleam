import player

@external(javascript, "./raylib_ffi.mjs", "init_window")
pub fn init_window(width:Int,heigth:Int,title:String) -> Nil


@external(javascript, "./raylib_ffi.mjs", "should_windows_close")
pub fn should_windows_close() -> Bool

@external(javascript, "./raylib_ffi.mjs", "close_window")
pub fn close_window() -> Nil

@external(javascript, "./raylib_ffi.mjs", "begin_drawing")
pub fn begin_drawing() -> Nil

@external(javascript, "./raylib_ffi.mjs", "clear_background")
pub fn clear_background() -> Nil

@external(javascript, "./raylib_ffi.mjs", "end_drawing")
pub fn end_drawing() -> Nil

@external(javascript, "./raylib_ffi.mjs", "draw_rectangle_rect")
pub fn draw_rectangle_rect(rect:player.Rectangle) -> Nil


// fps -------

@external(javascript, "./raylib_ffi.mjs", "set_target_fps")
pub fn set_target_fps(fps:Int) -> Nil

@external(javascript, "./raylib_ffi.mjs", "get_delta_time")
pub fn get_delta_time() -> Float

@external(javascript, "./raylib_ffi.mjs", "get_fps")
pub fn get_fps() -> Float



// textures ------------------

pub type Texture
@external(javascript, "./raylib_ffi.mjs", "load_texture")
pub fn load_texture(path:String) -> Texture

@external(javascript, "./raylib_ffi.mjs", "draw_texture")
pub fn draw_texture(texture:Texture,pos_x:Float,pos_y:Float) -> Nil

@external(javascript, "./raylib_ffi.mjs", "unload_texture")
pub fn unload_texture(texture:Texture) -> Nil

//input -------

pub type Key = Int

@external(javascript, "./raylib_ffi.mjs", "is_key_pressed")
pub fn is_key_pressed(key:Key) -> Bool

// Check if a key is being pressed
@external(javascript, "./raylib_ffi.mjs", "is_key_down")
pub fn is_key_down(key:Key) -> Bool

// Check if a key has been released once
@external(javascript, "./raylib_ffi.mjs", "is_key_released")
pub fn is_key_released(key:Key) -> Bool
// Check if a key is NOT being pressed
@external(javascript, "./raylib_ffi.mjs", "is_key_up")
pub fn is_key_up(key:Key) -> Bool

// // Get key pressed (keycode), call it multiple times for keys queued, returns 0 when the queue is empty
@external(javascript, "./raylib_ffi.mjs", "get_key_pressed")
pub fn get_key_pressed() -> Key
// // Get char pressed (unicode), call it multiple times for chars queued, returns 0 when the queue is empty
@external(javascript, "./raylib_ffi.mjs", "get_char_pressed")
pub fn get_char_pressed()-> Key



// collisons ----
@external(javascript, "./raylib_ffi.mjs", "check_collison_rect")
pub fn check_collison_rect(rec1:player.Rectangle,rec2:player.Rectangle) -> Bool
