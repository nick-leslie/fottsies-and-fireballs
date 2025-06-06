import gleam/option
import gleam/io
// import raylib

type Rectangle {
  Rectangle(
    x:Int,
    y:Int,
    width:Int,
    height:Int
  )
}

type EditorState {
  EditorState(
    img_path:option.Option(String),
    should_exit:Bool
  )
}

type EditorMsg {
  Continue
  UpadateImgPath(String)
  Exit
}

pub fn main() {
  io.println("Hello from editor!")
}

fn main_loop(state:EditorState) {
  let msg = view(state)
  case msg {
    Exit -> Nil
    _ -> {
      let state = update(state,msg)
      main_loop(state)
    }
  }
}

fn update(state:EditorState, msg:EditorMsg) -> EditorState{
  case msg {
    Exit -> state
    UpadateImgPath(path) -> todo
  }
}

fn view(state:EditorState) -> EditorMsg{

}


fn render_button(rect,msg) {

}
