import gleam/order
import physics/basics.{Rectangle, type Rectangle,type RiggdBody}
import physics/vector2
import gleam/option
import gleam/float
import gleam/list
import gleam/function

pub fn body_to_static(
  r_box:Rectangle,
  r_body:RiggdBody,
  static:Rectangle
) {
  let width_mod = case float.compare(r_body.vel.x, 0.0) {
    order.Eq -> 0.0
    order.Gt -> r_box.width
    order.Lt -> 0.0
  }
  let may_collide = line_rect_collision(
    vector2.from_tuple(#(r_box.x +. width_mod,r_box.y +. r_box.height)),
    vector2.from_tuple(#(r_box.x +. width_mod +. r_body.vel.x,{r_box.y +. r_box.height /. 2.0 } +. r_body.vel.x))
  ,static)
  case may_collide {
    option.None -> todo
    option.Some(_) -> todo
  }
}

//todo what if I take the all the points between

//return the two riddged bodys at the point were the collion occured
pub fn moving_box_collision(
  a_box:Rectangle,
  a_body:RiggdBody,
  b_box:Rectangle,
  b_body:RiggdBody,) {
  //move the rectangle long the line
  let a_start = vector2.Vector2(a_body.pos.x,a_body.pos.y)
  let a_end = vector2.Vector2(a_body.pos.x +. a_body.vel.x,a_body.pos.y +. a_body.pos.y)

  let b_start = vector2.Vector2(b_body.pos.x,b_body.pos.y)
  let b_end = vector2.Vector2(b_body.pos.x +. b_body.vel.x,b_body.pos.y +. b_body.pos.y)

  case line_line(a_start,a_end,b_start,b_end) {
    Error(_) -> {
      //todo parallel check
      todo
    }
    Ok(vector2.Vector2(x,y)) -> {
      //velocitys def colliding move to around that pont
      let a_width_mod = case float.compare(a_body.vel.x, 0.0) {
        order.Eq -> 0.0
        order.Gt -> a_box.width
        order.Lt -> 0.0
      }
      let b_width_mod = case float.compare(a_body.vel.x, 0.0) {
        order.Eq -> 0.0
        order.Gt -> a_box.width
        order.Lt -> 0.0
      }
      //because we are setting the collion twice we phase throuhg the world
      //todo we need a hight mod as well
      //todo this assumes that we
      let a_moved = basics.move_by(a_body,
        vector2.Vector2(
          {x -. a_width_mod -. a_box.x} *. -1.0,
          {y -. b_width_mod -. a_box.y} *. -1.0,
        )
      )
      let b_moved = basics.move_by(a_body,
        vector2.Vector2(
          {x -. a_box.width -. a_box.x} *. -1.0,
          {y -. a_box.height -. a_box.y} *. -1.0,
        )
      )
      let a_box = collider_to_body(a_box,a_moved)
      let b_box = collider_to_body(b_box,b_moved)
       case collison_rect(a_box,b_box) {
         False -> todo
         True -> todo
       }

      //its because we are adding the y of the wall
    }
  }

}

pub fn collider_to_body(box:Rectangle,body:RiggdBody) {
  Rectangle(..box,x:box.x +. body.pos.x,y:box.y +. body.pos.y)
}


pub fn collison_rect(rect1:Rectangle,rect2:Rectangle) {
  rect1.x <=. rect2.x +. rect2.width
  && rect1.x +. rect1.width >=. rect2.x
  && rect1.y <=. rect2.y +. rect2.height
  && rect1.y +. rect1.height >=. rect2.y
}


pub fn line_rect_collision(
  line_start: vector2.Vector2,
  line_end: vector2.Vector2,
  rect:Rectangle
) -> option.Option(vector2.Vector2) {

  // Calculate the edges of the rectangle


  // Check intersection with each side of the rectangle
  let intersections =
    [
      line_line(line_start,line_end, vector2.Vector2(rect.x,rect.y), vector2.Vector2(rect.x +. rect.width,rect.y)), // top
      line_line(line_start,line_end, vector2.Vector2(rect.x,rect.y), vector2.Vector2(rect.x, rect.y+.rect.height)),    // left
      line_line(line_start,line_end, vector2.Vector2(rect.x+.rect.width,rect.y), vector2.Vector2(rect.x+.rect.width,rect.y+.rect.height)), // Right
      line_line(line_start,line_end, vector2.Vector2(rect.x,rect.y+.rect.height),vector2.Vector2(rect.x+.rect.width,rect.y+.rect.height)),   // bot
    ]
    |> list.filter_map(function.identity)

  // Return the first intersection point, if any
  case intersections {
    [] -> option.None
    [first, ..] -> option.Some(first)
  }
}
// Helper function to check for intersection with a line segment



pub fn line_line(
  start1: vector2.Vector2,
  end1:   vector2.Vector2,
  start2: vector2.Vector2,
  end2:   vector2.Vector2
) -> Result(vector2.Vector2,Nil) {
  let vector2.Vector2(x1,y1) = start1
  let vector2.Vector2(x2,y2) = end1
  let vector2.Vector2(x3,y3) = start2
  let vector2.Vector2(x4,y4) = end2
  let a1 = y2 -. y1
  let b1 = x1 -. x2
  let c1 = a1 *. x1 +. b1 *. y1
  let a2 = y4 -. y3
  let b2 = x3 -. x4
  let c2 = a2 *. x3 +. b2 *. y3
  let det = a1 *. b2 -. a2 *. b1

  case det != 0.0 {
    True -> {
      let x = {b2 *. c1 -. b1 *. c2} /. det
      let y = {a1 *. c2 -. a2 *. c1} /. det

      case
        x >=. float.min(x1, x2)
        && x <=. float.max(x1, x2)
        && x >=. float.min(x3, x4)
        && x <=. float.max(x3, x4)
        && y >=. float.min(y1, y2)
        && y <=. float.max(y1, y2)
        && y >=. float.min(y3, y4)
        && y <=. float.max(y3, y4)
      {
        True -> Ok(vector2.Vector2(x, y))
        False -> Error(Nil)
      }
    }
    False -> Error(Nil)
  }
}
