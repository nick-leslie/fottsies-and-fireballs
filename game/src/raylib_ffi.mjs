import r from "raylib"

export function init_window(screenWidth,screenHeight,title) {
  r.InitWindow(screenWidth, screenHeight, "raylib [core] example - basic window")

}

export function set_target_fps(fps) {
  r.SetTargetFPS(fps)
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
