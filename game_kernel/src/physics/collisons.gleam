import gleam/result
import gleam/io
import gleam/order
import raylib.{type Rectangle,Rectangle}
import physics/basics.{type RiggdBody}
import physics/vector2.{Vector2,type Vector2}
import gleam/option
import gleam/float
import gleam/list
import gleam/function
type Support = fn (Vector2) -> Vector2

fn support(dir:Vector2,support_a:Support,support_b:Support) {
  let a = support_a(dir)
  let b = support_b(vector2.inverse(dir))
  Vector2(
    x: a.x -. b.x,
    y: a.y -. b.y
  )
}
type GJKPerams {
  GJKPerams(
    a_support:Support,
    b_support:Support,
    itter:Int,
    max_itter:Int,
    dir:Vector2,
    simplex:List(Vector2)
  )
}

fn gjk(a_support:Support,b_support:Support) {
  let first = support(Vector2(1.0,0.0),a_support,b_support)
  let simplex = [first]
  let perams = GJKPerams(
    a_support: ,
    b_support: ,
    itter: 0,
    max_itter: 100,
    dir: vector2.inverse(first),
    simplex: )
  gjk_loop(perams)
}
//moddled after https://github.com/bryanchacosky/gjk.java/blob/master/GJK.java
fn gjk_loop(perams:GJKPerams) {
  case perams.itter > perams.max_itter {
    False -> {
      let new_point = support(perams.dir,perams.a_support,perams.b_support)
      case vector2.dot(new_point,perams.dir) <=. 0.0 {
        True -> Error("No collision (new point not past the origin)")
        False -> {
          let simplex = list.append([new_point],perams.simplex)
          //todo we want to simplify this by making the return logic less nested
          case simplex {
            [zero, one] -> {
              let #(sim,dir) = line_case(zero,one)
                gjk_loop(GJKPerams(..perams,
                  itter:perams.itter+1,
                  simplex: sim,
                  dir:
                ))
            }
            [zero, one,two] -> {
              let triangle = triangle_case(zero,one,two)
              case triangle {
                Ok(sim) -> {
                  // "test" |> echo
                  // perams |> echo
                  sim |> echo
                  Ok(sim)
                } // todo return point
                Error(#(sim,dir)) -> gjk_loop(GJKPerams(..perams,
                  itter:perams.itter+1,
                  simplex: sim,
                  dir:,
                ))
              }
            }
            _ -> Error("no collion")
          }
          }
      }
    }
    True -> Error("max itter depth reached may not be acurate")
  }
}

pub fn line_case(a:Vector2,b:Vector2) {
  let ab = Vector2( x: b.x -. a.x, y: b.y -. a.y )
  let ao = Vector2( x: a.x *. -1.0, y: a.y *. -1.0 )
  let direction = case vector2.dot(Vector2(ab.y *. -1.0,ab.x),ao) >. 0.0 {
    False -> Vector2(ab.y *. -1.0,ab.x)
    True -> Vector2(ab.y *. -1.0,ab.x *. -1.0)
  }
  case vector2.dot(ab, ao) >. 0.0 { // same dir
    True -> #([a,b],direction) // change direction
    False -> #([a],ao)
  }
}
pub fn triangle_case(a:Vector2,b:Vector2,c:Vector2) {
  let ab = Vector2(x: b.x -. a.x, y: b.y -. a.y )
  let ac = Vector2(x: c.x -. a.x, y: c.y -. a.y )
  let ao = Vector2(x: a.x *. -1.0, y: a.y *. -1.0)
  // let ab_perp =vector2.cross(vector2.cross(ac,ab),ab)
  // let ac_perp =vector2.cross(vector2.cross(ab,ac),ac)
  // let abc = vector2.cross(ab,ac)
  // let ab_perp = Vector2(x: ab.y *. -1.0, y: ab.x ) // Perpendicular to AB, pointing outwards
  let direction = case vector2.dot(Vector2(ab.y *. -1.0,ab.x),c) >. 0.0 {
    False -> Vector2(ab.y *. -1.0,ab.x)
    True -> Vector2(ab.y *. -1.0,ab.x *. -1.0)
  }
  case vector2.dot(direction,ao) >. 0.0 {
    True -> {
      Error(#([b,a],direction))
    }
    False -> {

      let direction = case vector2.dot(Vector2(ac.y *. -1.0,ac.x),b) >. 0.0 {
        False -> Vector2(ac.y *. -1.0,ac.x)
        True -> Vector2(ac.y,ac.x *. -1.0)
      }
      // let direction = Vector2(ac.y *. -1.0,ac.x)
      case vector2.dot(direction,ao) >. 0.0 {
        True -> Error(#([c,a],direction))
        False -> Ok([a,b,c])
      }
    }
  }
}
//tod o(n)
fn point_support(dir:Vector2,points:List(Vector2)) {
  {
    let assert Ok(first) = list.first(points)
    use #(_furthest_point,dist) as old,point <- list.fold(points,#(first,vector2.dot(first,dir)))
    let new_dist = vector2.dot(point,dir)
    case new_dist >=. dist {
      False -> old
      True -> #(point,new_dist)
    }
  }.0
}

pub fn rect_rect_gjk(a:Rectangle,b:Rectangle) {
  let a_support = fn (dir) {
    point_support(dir,points_from_rect(a))
  }
  let b_support = fn (dir) {
    point_support(dir,points_from_rect(b))

  }
  gjk(a_support,b_support)
}

fn points_from_rect(rect:Rectangle) {
  [
    Vector2(rect.x +. {rect.width /. 2.0 }, rect.y -. { rect.height /. 2.0}),
    Vector2(rect.x -. {rect.width /. 2.0 }, rect.y -. { rect.height /. 2.0}),
    Vector2(rect.x +. {rect.width /. 2.0 }, rect.y +. { rect.height /. 2.0}),
    Vector2(rect.x -. {rect.width /. 2.0 }, rect.y +. { rect.height /. 2.0}),
  ]
}

//return the two riddged bodys at the point were the collion occured
pub fn moving_box_collision(
  a_box:Rectangle,
  a_body:RiggdBody,
  b_box:Rectangle,
  b_body:RiggdBody,) -> Result(Vector2, String) {
  let a_box =  collider_to_body_space(a_box,a_body)
  let b_box =  collider_to_body_space(b_box,b_body)
  let next_a = collider_next_pos(a_box,a_body)
  let next_b = collider_next_pos(b_box,b_body)
  let a_support = fn (dir) {
    point_support(dir,list.append(
      points_from_rect(a_box),
      points_from_rect(next_a),
    ))
  }
  let b_support = fn (dir) {
    point_support(dir,list.append(
      points_from_rect(b_box),
      points_from_rect(next_b),
    ))
  }
  case gjk(a_support,b_support) {
    Error(err) -> Error(err)
    Ok(point) -> {
       Ok(Vector2(0.0,0.0))
    }
  }
}


pub fn collider_to_body_space(box:Rectangle,body:RiggdBody) {
  Rectangle(..box,x:box.x +. body.pos.x,y:box.y +. body.pos.y)
}

pub fn collider_next_pos(box:Rectangle,body:RiggdBody) {
  Rectangle(..box,x:box.x +. body.vel.x,y:box.y +. body.vel.y)
}


pub fn collison_rect(rect1:Rectangle,rect2:Rectangle) {
  rect1.x <=. rect2.x +. rect2.width
  && rect1.x +. rect1.width >=. rect2.x
  && rect1.y <=. rect2.y +. rect2.height
  && rect1.y +. rect1.height >=. rect2.y
}


pub fn line_rect_collision(
  line_start: Vector2,
  line_end: Vector2,
  rect:Rectangle
) -> option.Option(Vector2) {

  // Calculate the edges of the rectangle


  // Check intersection with each side of the rectangle
  let intersections =
    [
      line_line(line_start,line_end, Vector2(rect.x,rect.y), Vector2(rect.x +. rect.width,rect.y)), // top
      line_line(line_start,line_end, Vector2(rect.x,rect.y), Vector2(rect.x, rect.y+.rect.height)),    // left
      line_line(line_start,line_end, Vector2(rect.x+.rect.width,rect.y), Vector2(rect.x+.rect.width,rect.y+.rect.height)), // Right
      line_line(line_start,line_end, Vector2(rect.x,rect.y+.rect.height),Vector2(rect.x+.rect.width,rect.y+.rect.height)),   // bot
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
  start1: Vector2,
  end1:   Vector2,
  start2: Vector2,
  end2:   Vector2
) -> Result(Vector2,Nil) {
  let Vector2(x1,y1) = start1
  let Vector2(x2,y2) = end1
  let Vector2(x3,y3) = start2
  let Vector2(x4,y4) = end2
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
        True -> Ok(Vector2(x, y))
        False -> Error(Nil)
      }
    }
    False -> Error(Nil)
  }
}
