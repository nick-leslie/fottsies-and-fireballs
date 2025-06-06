pub type Rectangle {
  Rectangle(
    width:Float,
    height:Float,
    x:Float,
    y:Float
  )
}
pub type Color {
  Color(
    r:Int,
    g:Int,
    b:Int,
    a:Int,
  )
}

pub const ray_white = Color(
  r:245,
  g:245,
  b:245,
  a:255
)

pub const ray_blue = Color(r: 0, g: 121, b: 241, a: 255 )

pub const light_gray = Color( r: 200, g: 200, b: 200, a: 255 )
pub const red=Color( r: 230, g: 41, b: 55, a: 255 )
pub const green= Color ( r: 0, g: 228, b: 48, a: 255 )
// pub const gray: { r: 130, g: 130, b: 130, a: 255 }
// pub const DARKGRAY: { r: 80, g: 80, b: 80, a: 255 }
// pub const YELLOW: { r: 253, g: 249, b: 0, a: 255 }
// pub const GOLD: { r: 255, g: 203, b: 0, a: 255 }
// pub const ORANGE: { r: 255, g: 161, b: 0, a: 255 }
// pub const PINK: { r: 255, g: 109, b: 194, a: 255 }
// pub const MAROON: { r: 190, g: 33, b: 55, a: 255 }
// pub const LIME: { r: 0, g: 158, b: 47, a: 255 }
// pub const DARKGREEN: { r: 0, g: 117, b: 44, a: 255 }
// pub const SKYBLUE: { r: 102, g: 191, b: 255, a: 255 }
// pub const BLUE: { r: 0, g: 121, b: 241, a: 255 }
// pub const DARKBLUE: { r: 0, g: 82, b: 172, a: 255 }
// pub const PURPLE: { r: 200, g: 122, b: 255, a: 255 }
// pub const VIOLET: { r: 135, g: 60, b: 190, a: 255 }
// pub const DARKPURPLE: { r: 112, g: 31, b: 126, a: 255 }
// pub const BEIGE: { r: 211, g: 176, b: 131, a: 255 }
// pub const BROWN: { r: 127, g: 106, b: 79, a: 255 }
// pub const DARKBROWN: { r: 76, g: 63, b: 47, a: 255 }
// pub const WHITE: { r: 255, g: 255, b: 255, a: 255 }
// pub const BLACK: { r: 0, g: 0, b: 0, a: 255 }
// pub const BLANK: { r: 0, g: 0, b: 0, a: 0 }
// pub const MAGENTA: { r: 255, g: 0, b: 255, a: 255 }
// pub const RAYWHITE: { r: 245, g: 245, b: 245, a: 255 }


@external(javascript, "./raylib_ffi.mjs", "init_window")
pub fn init_window(width:Int,heigth:Int,title:String) -> Nil


@external(javascript, "./raylib_ffi.mjs", "should_windows_close")
pub fn should_windows_close() -> Bool

@external(javascript, "./raylib_ffi.mjs", "close_window")
pub fn close_window() -> Nil

@external(javascript, "./raylib_ffi.mjs", "draw_fps")
pub fn draw_fps(x:Float,y:Float) -> Nil

@external(javascript, "./raylib_ffi.mjs", "begin_drawing")
pub fn begin_drawing() -> Nil

@external(javascript, "./raylib_ffi.mjs", "clear_background")
pub fn clear_background() -> Nil

@external(javascript, "./raylib_ffi.mjs", "end_drawing")
pub fn end_drawing() -> Nil

@external(javascript, "./raylib_ffi.mjs", "draw_rectangle")
pub fn draw_rectangle(x:Float,y:Float,width:Float,height:Float,color:Color) -> Nil

@external(javascript, "./raylib_ffi.mjs", "draw_rectangle_rect")
pub fn draw_rectangle_rect(rect:Rectangle) -> Nil

@external(javascript, "./raylib_ffi.mjs", "draw_line")
pub fn draw_line(start_pos_x:Float, start_pos_y:Float, end_pos_x:Float, end_pos_y:Float) -> Nil


// fps -------

@external(javascript, "./raylib_ffi.mjs", "set_target_fps")
pub fn set_target_fps(fps:Int) -> Nil

@external(javascript, "./raylib_ffi.mjs", "get_delta_time")
pub fn get_delta_time() -> Float

@external(javascript, "./raylib_ffi.mjs", "get_fps")
pub fn get_fps() -> Float



// textures ------------------

pub type Texture{
  Texture(
    id:Int,
    width:Float,
    height:Float,
    mipmaps:Int,
    format:Int
  )
}
@external(javascript, "./raylib_ffi.mjs", "load_texture")
pub fn load_texture(path:String) -> Texture

@external(javascript, "./raylib_ffi.mjs", "draw_texture")
pub fn draw_texture(texture:Texture,pos_x:Float,pos_y:Float) -> Nil

@external(javascript, "./raylib_ffi.mjs", "draw_texture_rect")
pub fn draw_texture_rect(texture:Texture,source:Rectangle,pos_x:Float,pos_y:Float,color:Color) -> Nil

@external(javascript, "./raylib_ffi.mjs", "draw_texture_pro")
pub fn draw_texture_pro(texture texture:Texture,source source:Rectangle,dest dest:Rectangle,x pos_x:Float,y pos_y:Float,rot rot:float,tint tint:Color) -> Nil

@external(javascript, "./raylib_ffi.mjs", "draw_texture_ex")
pub fn draw_texture_ex(texture:Texture,pos_x:Float,pos_y:Float,rot:Float,scale:Float,color:Color) -> Nil

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
pub fn check_collison_rect(rec1:Rectangle,rec2:Rectangle) -> Bool


//cam ----
pub type Vector2 {
  Vector2(x:Float,y:Float)
}

pub type Camera {
  Camera(
    offset:Vector2,
    target:Vector2,
    rotation:Float,
    zoom:Float
  )
}

@external(javascript, "./raylib_ffi.mjs", "new_cam")
pub fn new_cam(offset_x:Float,offset_y:Float,target_x:Float,target_y:Float,rot:Float,zoom:Float) -> Camera

@external(javascript, "./raylib_ffi.mjs", "begin_mode_2d")
pub fn begin_mode_2d(cam:Camera) -> Nil

@external(javascript, "./raylib_ffi.mjs", "end_mode_2d")
pub fn end_mode_2d(cam:Camera) -> Nil

@external(javascript, "./raylib_ffi.mjs", "get_world_to_screen2d")
pub fn get_world_to_screen2d(pos:Vector2,cam:Camera) -> Vector2

@external(javascript, "./raylib_ffi.mjs", "get_screen_to_world")
pub fn get_screen_to_world(pos:Vector2,cam:Camera) -> Vector2


@external(javascript, "./raylib_ffi.mjs", "gui_button")
pub fn gui_button(rectangle:Rectangle, txt:String) ->Bool

@external(javascript, "./raylib_ffi.mjs", "gui_textbox")
pub fn gui_textbox(rectangle:Rectangle, txt:String,text_size:Int,edit_mode:Bool)->Bool
