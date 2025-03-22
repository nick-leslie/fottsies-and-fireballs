import r from "raylib"

export function init_window(screenWidth,screenHeight,title) {
  r.InitWindow(screenWidth, screenHeight, "raylib [core] example - basic window")

}


export function should_windows_close() {
  return r.WindowShouldClose()
}
export function get_char_pressed() {
  return r.GetCharPressed()
}
export function close_window() {
  r.CloseWindow()
}

export function begin_drawing() {
  r.BeginDrawing()

}

export function clear_background() {
  r.ClearBackground(r.RAYWHITE)
}

export function end_drawing() {
  r.EndDrawing()
}

//fps
export function set_target_fps(fps) {
  r.SetTargetFPS(fps)
}
export function get_delta_time() {
  return r.GetFrameTime(fps)
}

export function get_fps() {
  return r.GetFPS()
}

export function draw_rectangle_rect(rect) {
  r.DrawRectangleRec(rect, r.BLUE)
}

//texures -----
export function load_texture(path) {
  return r.LoadTexture(path)
}
export function draw_texture(texture,posX,posY) {
  r.DrawTexture(texture,posX,posY,r.RAYWHITE)
}
export function unload_texture(texture) {
  r.UnloadTexture(texture)
}


//----- Input
// Check if a key has been pressed once
export function is_key_pressed(key) {
  return r.IsKeyPressed(key)
}

// Check if a key is being pressed
export function is_key_down(key) {
  return r.IsKeyDown(key)
}

// Check if a key has been released once
export function is_key_released(key) {
  return r.IsKeyReleased(key)
}
// Check if a key is NOT being pressed
export function is_key_up(key) {
  return r.IsKeyUp(key)
}

// // Get key pressed (keycode), call it multiple times for keys queued, returns 0 when the queue is empty
export function get_key_pressed() {
  return r.GetKeyPressed()
}
// // Get char pressed (unicode), call it multiple times for chars queued, returns 0 when the queue is empty
export function get_char_pressed() {
  return r.GetCharPressed()
}

export function check_collison_rect(rec1,rec2) {
  return r.CheckCollisionRecs(rec1, rec2)
}
