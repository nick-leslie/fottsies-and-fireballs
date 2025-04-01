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
    simplex:List(Vector2)
  )
}

fn gjk(a_support:Support,b_support:Support) {
  let simplex = [support(Vector2(1.0,0.0),a_support,b_support)]
  let perams = GJKPerams(
    a_support: ,
    b_support: ,
    itter: 0,
    max_itter: 100,
    simplex: )
  gjk_loop(perams)
}

fn gjk_loop(perams:GJKPerams) {
  case perams.itter > perams.max_itter {
    False -> {
      use last <- result.try(result.replace_error(list.last(perams.simplex),"No last item in simplex list something went wrong"))
      let dir = vector2.inverse(last)
      let new_point = support(dir,perams.a_support,perams.b_support)
      case vector2.dot(new_point,dir) <=. 0.0 {
        True -> Error("No collision (new point not past the origin)")
        False -> {
          let simplex = list.append(perams.simplex,[new_point]) |> echo
          //todo we want to simplify this by making the return logic less nested
          case simplex {
            [zero, one] -> {
              let #(sim,col) = line_case(one,zero)
              case col {
                True ->  Ok(sim) //todo return point
                False -> gjk_loop(GJKPerams(..perams,
                   itter:perams.itter+1,
                   simplex: sim
                 )) |> echo
              }
            }
            [zero, one,two] -> {
              let #(sim,col) = triangle_case(two,zero,one)
              case col {
                True -> Ok(sim) // todo return point
                False -> gjk_loop(GJKPerams(..perams,
                  itter:perams.itter+1,
                  simplex: sim
                )) |> echo
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
  let ab_dot_ao = vector2.dot(ab, ao)
  let ab_dot_ab = vector2.dot(ab, ab)
  case ab_dot_ao <=. 0.0 {
    True -> #([a],True)
    False -> case ab_dot_ao >=. ab_dot_ab {
      False -> #([a,b],True)
      True -> {
        #([b],False)
      }
    }
  }
}
pub fn triangle_case(a:Vector2,b:Vector2,c:Vector2) {
  let ab = Vector2( x: b.x -. a.x, y: b.y -. a.y )
  let ac = Vector2(x: c.x -. a.x, y: c.y -. a.y )
  let ao = Vector2(x: a.x *. -1.0, y: a.y *. -1.0)

  let ab_perp = Vector2(x: ab.y *. -1.0, y: ab.x ) // Perpendicular to AB, pointing outwards
  case vector2.dot(ab_perp,ao) >. 0.0 {
    True -> #([b,a],False)
    False -> {
      let ac_perp = Vector2( x: ac.y *. -1.0, y: ac.x )
      case vector2.dot(ac_perp,ao) <. 0.0 {
        True -> #([c,a],False)
        False -> #([c,b,a],True)
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
    point_support(dir,[
      Vector2(a.x,a.y),
      Vector2(a.x +. a.width,a.y),
      Vector2(a.x, a.y+.a.height),
      Vector2(a.x +. a.width, a.y+.a.height),
    ])
  }
  let b_support = fn (dir) {
    point_support(dir,[
      Vector2(b.x,b.y),
      Vector2(b.x +. b.width,a.y),
      Vector2(b.x, b.y+.b.height),
      Vector2(b.x +. b.width, b.y+.b.height),
    ])

  }
  gjk(a_support,b_support)
}

//return the two riddged bodys at the point were the collion occured
pub fn moving_box_collision(
  a_box:Rectangle,
  a_body:RiggdBody,
  b_box:Rectangle,
  b_body:RiggdBody,) {


    // let relitive_var = sub(a_body.vel,b_body.vel) |> io.debug
    // raylib.draw_rectangle_rect(minkowski_rect)
    // let col = line_rect_collision(Vector2(0.0,0.0),relitive_var,minkowski_rect) |> io.debug
    // case col {
    //   option.None -> option.None
    //   option.Some(point) -> option.Some(point)
    // }
        //}
      // True -> {
      //   let relitive_var = sub(a_body.vel,b_body.vel)

      // }
    // }
    //todo advanced collion

}


pub fn collider_to_body_space(box:Rectangle,body:RiggdBody) {
  Rectangle(..box,x:box.x +. body.pos.x,y:box.y +. body.pos.y)
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
