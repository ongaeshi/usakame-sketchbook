# uk generate "モダンな私の家を歩き回るゲーム。画面端までいくと隣の部屋に移動。家は２階建てで複数の部屋で構成されている。（後からタイルマップエディタで編集できるようにしておいてほしい。）。部屋の中には複数のレコードが置いてあり選択すると取れる。取得したCDを家の中心にあるレコードプレイヤーにかけると音楽が再生される。キャラクタや部屋のタイルや壁のスプライトは絵文字を使わずに基本的に自作してほしい。" -o myroom.rb
#
# ==============================================================================
# MYROOM - A Cozy 2-Story Modern House Exploration Game
# Controls:
#   [ARROWS] / [WASD] : Move character
#   [Z] / [SPACE]     : Pick up vinyl / Operate Turntable / Change Track
#   [X]               : Stop music
# ==============================================================================

$frame = 0
$px = 120
$py = 140
$pdir = 0 # 0:down, 1:up, 2:left, 3:right
$pwalk = 0
$moving = false

# Current Room Coordinates: [rx, ry]
# 1F: (0,1) Kitchen, (1,1) Living Room, (2,1) Garden
# 2F: (0,0) Bedroom, (1,0) Study/Loft,  (2,0) Balcony
$rx = 1
$ry = 1

# Records scattered across rooms:
# rx, ry, tx, ty (tile coords), name, color_id, color_name, collected
$records = [
  { id: 0, rx: 0, ry: 0, tx: 5,  ty: 6,  name: "LOFI BEDROOM", col: 12, cname: "BLUE",  got: false },
  { id: 1, rx: 0, ry: 1, tx: 4,  ty: 7,  name: "COFFEE GROOVE", col: 8,  cname: "RED",   got: false },
  { id: 2, rx: 2, ry: 1, tx: 10, ty: 10, name: "GARDEN BREEZE", col: 11, cname: "GREEN", got: false },
  { id: 3, rx: 2, ry: 0, tx: 9,  ty: 8,  name: "MIDNIGHT SUN",  col: 10, cname: "GOLD",  got: false }
]

$inventory = []
$now_playing = nil # nil or record hash
$music_frame = 0
$spin_angle = 0
$msg = "WELCOME TO MY ROOM!"
$msg_timer = 180
$notes = []

# Audio frequency table for 4 distinct retro background melodies
$tracks = [
  # Track 0: Lofi Bedroom (chill pentatonic chords)
  [261, 329, 392, 523, 392, 329, 293, 349, 440, 523, 440, 349],
  # Track 1: Coffee Groove (funky bassline & beats)
  [196, 196, 261, 293, 329, 261, 196, 220, 246, 293, 220, 196],
  # Track 2: Garden Breeze (bright ascending melodies)
  [329, 392, 440, 493, 587, 493, 440, 392, 349, 440, 523, 440],
  # Track 3: Midnight Sun (jazzy dreamscape)
  [220, 277, 329, 415, 329, 277, 246, 311, 370, 466, 370, 311]
]

def show_msg(text)
  $msg = text
  $msg_timer = 140
end

def solid_tile?(tid)
  # Solid furniture and walls
  return true if tid == 2 || tid == 3 || tid == 4 || tid == 5 || tid == 6 || tid == 7 || tid == 11 || tid == 12 || tid == 13
  false
end

def can_pass?(cx, cy)
  return false if cx < 0 || cx >= 48 || cy < 0 || cy >= 32
  tid = mget(cx, cy)
  return true if tid.nil?
  !solid_tile?(tid)
end

def can_move_to?(x, y)
  # Bounding box 12x8 at feet (x+2 .. x+14, y+8 .. y+16)
  world_gx = $rx * 16
  world_gy = $ry * 16

  t1 = [(world_gx + (x + 3) / 16), (world_gy + (y + 10) / 16)]
  t2 = [(world_gx + (x + 13) / 16), (world_gy + (y + 10) / 16)]
  t3 = [(world_gx + (x + 3) / 16), (world_gy + (y + 15) / 16)]
  t4 = [(world_gx + (x + 13) / 16), (world_gy + (y + 15) / 16)]

  can_pass?(t1[0], t1[1]) && can_pass?(t2[0], t2[1]) && can_pass?(t3[0], t3[1]) && can_pass?(t4[0], t4[1])
end

def update
  $frame += 1
  $msg_timer -= 1 if $msg_timer > 0

  # Player Movement
  speed = 2
  $moving = false
  dx = 0
  dy = 0

  if btn(0) # Left
    dx -= speed
    $pdir = 2
    $moving = true
  elsif btn(1) # Right
    dx += speed
    $pdir = 3
    $moving = true
  end

  if btn(2) # Up
    dy -= speed
    $pdir = 1
    $moving = true
  elsif btn(3) # Down
    dy += speed
    $pdir = 0
    $moving = true
  end

  # Diagonal dampening
  if dx != 0 && dy != 0
    dx = (dx > 0 ? 1 : -1)
    dy = (dy > 0 ? 1 : -1)
  end

  # Horizontal step
  if dx != 0
    nx = $px + dx
    if can_move_to?(nx, $py)
      $px = nx
    end
  end

  # Vertical step
  if dy != 0
    ny = $py + dy
    if can_move_to?($px, ny)
      $py = ny
    end
  end

  if $moving
    $pwalk += 1
  else
    $pwalk = 0
  end

  # Room Screen Transition (at boundaries)
  if $px < 2
    if $rx > 0
      $rx -= 1
      $px = 238
      show_msg("ENTERED " + room_name($rx, $ry))
    else
      $px = 2
    end
  elsif $px > 238
    if $rx < 2
      $rx += 1
      $px = 2
      show_msg("ENTERED " + room_name($rx, $ry))
    else
      $px = 238
    end
  end

  # Check Stairs (tile 8: stairs up, tile 9: stairs down)
  foot_cx = $rx * 16 + ($px + 8) / 16
  foot_cy = $ry * 16 + ($py + 12) / 16
  current_tile = mget(foot_cx, foot_cy)

  if current_tile == 8 # Going upstairs
    $ry = 0
    $rx = 1
    $px = 120
    $py = 180
    show_msg("WENT UP TO 2F")
  elsif current_tile == 9 # Going downstairs
    $ry = 1
    $rx = 1
    $px = 120
    $py = 90
    show_msg("WENT DOWN TO 1F")
  end

  # Interaction Button [Z]
  btn_z = btn(4)
  if btn_z && !$prev_z
    check_interactions
  end
  $prev_z = btn_z

  # Stop Music [X]
  if btn(5) && $now_playing
    $now_playing = nil
    show_msg("MUSIC STOPPED")
  end

  # Turntable & Music update
  if $now_playing
    $spin_angle = ($spin_angle + 6) % 360
    $music_frame += 1

    # Spawn floating music notes
    if $music_frame % 25 == 0
      $notes << {
        x: ($rx == 1 && $ry == 1) ? 128 : rand(200) + 28,
        y: ($rx == 1 && $ry == 1) ? 104 : rand(180) + 40,
        vy: -1.0,
        life: 45,
        type: ($music_frame / 25) % 2,
        col: $now_playing[:col]
      }
    end
  end

  # Update notes
  $notes.each do |n|
    n[:y] = n[:y] + n[:vy]
    n[:life] = n[:life] - 1
  end
  $notes.reject! { |n| n[:life] <= 0 }
end

def room_name(rx, ry)
  if ry == 1
    return "KITCHEN & DINING" if rx == 0
    return "LIVING ROOM (1F)" if rx == 1
    return "SUNNY TERRACE" if rx == 2
  else
    return "COZY BEDROOM" if rx == 0
    return "STUDY & LOFT (2F)" if rx == 1
    return "STARLIGHT BALCONY" if rx == 2
  end
  "HOUSE"
end

def check_interactions
  # 1. Check near Record Player (Located in Living Room rx:1, ry:1 around tile 7,6 / 8,6)
  if $rx == 1 && $ry == 1
    dist_player = (($px + 8) - 128).abs + (($py + 10) - 114).abs
    if dist_player < 26
      interact_turntable
      return
    end
  end

  # 2. Check nearby scattered Records
  $records.each do |rec|
    if !rec[:got] && rec[:rx] == $rx && rec[:ry] == $ry
      rec_px = rec[:tx] * 16 + 8
      rec_py = rec[:ty] * 16 + 8
      dist = (($px + 8) - rec_px).abs + (($py + 10) - rec_py).abs
      if dist < 22
        rec[:got] = true
        $inventory << rec
        show_msg("FOUND: " + rec[:name] + " (" + rec[:cname] + " VINYL)!")
        return
      end
    end
  end

  # Default interaction reminder
  if $inventory.size == 0
    show_msg("SEARCH ROOMS FOR VINYL RECORDS!")
  else
    show_msg("GO TO THE LIVING ROOM TURNTABLE [Z]")
  end
end

def interact_turntable
  if $inventory.size == 0
    show_msg("TURNTABLE IS EMPTY. GO FIND RECORDS!")
    return
  end

  # Cycle through collected records
  if $now_playing.nil?
    $now_playing = $inventory.first
  else
    cur_idx = -1
    $inventory.each_with_index do |rec, idx|
      cur_idx = idx if rec[:id] == $now_playing[:id]
    end
    next_idx = (cur_idx + 1) % $inventory.size
    $now_playing = $inventory[next_idx]
  end

  show_msg("NOW PLAYING: " + $now_playing[:name] + " ♪")
end

def draw
  cls(0)

  # Draw current room tilemap (16x16 cells)
  map($rx * 16, $ry * 16, 0, 0, 16, 16)

  # Draw Record Player at Living Room center (rx:1, ry:1)
  if $rx == 1 && $ry == 1
    draw_turntable(120, 100)
  end

  # Draw Records on the floor / furniture
  $records.each do |rec|
    if !rec[:got] && rec[:rx] == $rx && rec[:ry] == $ry
      rx_pos = rec[:tx] * 16
      ry_pos = rec[:ty] * 16
      # Floating shiny bobbing animation
      bob = ($frame % 30 < 15) ? 0 : -1
      spr(10, rx_pos, ry_pos + bob)
      # Vinyl label center color dot
      pset(rx_pos + 7, ry_pos + 7 + bob, rec[:col])
      pset(rx_pos + 8, ry_pos + 7 + bob, rec[:col])
    end
  end

  # Draw Player
  spr_id = 14 + ($pdir * 2) + (($moving && ($pwalk / 8) % 2 == 1) ? 1 : 0)
  spr(spr_id, $px, $py)

  # Draw Animated Floating Musical Notes
  $notes.each do |n|
    if n[:type] == 0
      # Single note ♪
      circfill(n[:x], n[:y], 2, n[:col])
      line(n[:x] + 2, n[:y], n[:x] + 2, n[:y] - 6, n[:col])
      line(n[:x] + 2, n[:y] - 6, n[:x] + 4, n[:y] - 5, n[:col])
    else
      # Double note ♫
      circfill(n[:x], n[:y], 1, n[:col])
      circfill(n[:x] + 5, n[:y], 1, n[:col])
      line(n[:x] + 1, n[:y], n[:x] + 1, n[:y] - 5, n[:col])
      line(n[:x] + 6, n[:y], n[:x] + 6, n[:y] - 5, n[:col])
      line(n[:x] + 1, n[:y] - 5, n[:x] + 6, n[:y] - 5, n[:col])
    end
  end

  # Top HUD Bar: Room Name & Floor Info
  rectfill(0, 0, 256, 16, 0)
  line(0, 16, 256, 16, 5)
  floor_str = ($ry == 1) ? "1F" : "2F"
  print_text("[" + floor_str + "] " + room_name($rx, $ry), 6, 4, 7)

  # Inventory icons on top-right
  print_text("RECS:" + $inventory.size.to_s + "/4", 196, 4, 10)

  # Music Visualizer Bar (when playing)
  if $now_playing
    rectfill(0, 17, 256, 11, 1)
    line(0, 28, 256, 28, 12)
    # Spinning mini vinyl
    spr(10, 4, 15, false, false, $spin_angle)
    pset(11, 22, $now_playing[:col])
    print_text("♪ " + $now_playing[:name], 24, 19, $now_playing[:col])

    # Equalizer animation
    (0..11).each do |i|
      eq_h = 2 + (sin(($frame * 0.2) + i * 1.2).abs * 7).to_i
      line(210 + i * 3, 26, 210 + i * 3, 26 - eq_h, 10)
    end
  end

  # Bottom Notification / Prompt Box
  if $msg_timer > 0
    rectfill(12, 230, 232, 18, 0)
    rect(12, 230, 232, 18, 6)
    print_text($msg, 18, 235, 10)
  else
    # Helper guide
    rectfill(0, 244, 256, 12, 0)
    print_text("ARROWS:MOVE | Z:ACTION | X:STOP", 16, 246, 5)
  end
end

def draw_turntable(x, y)
  # Wooden table base
  rectfill(x - 2, y + 4, 20, 14, 4)
  rect(x - 2, y + 4, 20, 14, 0)
  # Turntable metal chassis
  rectfill(x, y, 16, 12, 6)
  rect(x, y, 16, 12, 5)

  if $now_playing
    # Spinning vinyl record on table
    spr(10, x, y - 2, false, false, $spin_angle)
    # Center record color
    circfill(x + 8, y + 5, 2, $now_playing[:col])
    # Tonearm needle
    line(x + 13, y + 1, x + 9, y + 4, 7)
    pset(x + 13, y + 1, 8)
  else
    # Empty turntable platter
    circfill(x + 7, y + 6, 4, 5)
    circ(x + 7, y + 6, 4, 0)
    pset(x + 7, y + 6, 7)
    # Resting tonearm
    line(x + 13, y + 1, x + 13, y + 8, 7)
    pset(x + 13, y + 1, 8)
  end
end

__END__
# ==============================================================================
# SPRITE DEFINITIONS (16x16 Hex Pixel-Art)
# ==============================================================================

# 0: Empty / Transparent
@SPRITE 0
................
................
................
................
................
................
................
................
................
................
................
................
................
................
................
................

# 1: Wood Flooring
@SPRITE 1
4444444444444444
4FFFFFFFFFFFFFF4
4F444444444444F4
4FFFFFFFFFFFFFF4
4444444444444444
4FFFFFFFFFFFFFF4
4F444444444444F4
4FFFFFFFFFFFFFF4
4444444444444444
4FFFFFFFFFFFFFF4
4F444444444444F4
4FFFFFFFFFFFFFF4
4444444444444444
4FFFFFFFFFFFFFF4
4F444444444444F4
4FFFFFFFFFFFFFF4

# 2: Modern Wall Top (Dark Grey)
@SPRITE 2
5555555555555555
5555555555555555
5555555555555555
5555555555555555
5555555555555555
5555555555555555
5555555555555555
5555555555555555
5555555555555555
5555555555555555
5555555555555555
5555555555555555
5555555555555555
5555555555555555
0000000000000000
0000000000000000

# 3: Modern Wallpaper / Room Wall Bottom
@SPRITE 3
6666666666666666
6777777777777776
6777777777777776
6777777777777776
6777777777777776
6777777777777776
6777777777777776
6777777777777776
6777777777777776
6777777777777776
6777777777777776
6777777777777776
6777777777777776
6777777777777776
4444444444444444
5555555555555555

# 4: Wall with Sunny Window
@SPRITE 4
6666666666666666
6770000000000776
6770CCCC00CC0776
6770CCCC00CC0776
6770CCCC00CC0776
6770000000000776
6770CCCC00CC0776
6770CCCC00CC0776
6770CCCC00CC0776
6770000000000776
6777777777777776
6777777777777776
6777777777777776
6777777777777776
4444444444444444
5555555555555555

# 5: Bookshelf
@SPRITE 5
4444444444444444
48E88E849A99AA94
48E88E849A99AA94
4444444444444444
4CBCCBB4EE88EEE4
4CBCCBB4EE88EEE4
4444444444444444
49AA99A48E888E84
49AA99A48E888E84
4444444444444444
4EE88EE4CBCBCCC4
4EE88EE4CBCBCCC4
4444444444444444
4444444444444444
0000000000000000
................

# 6: Cozy Bed
@SPRITE 6
4444444444444444
4777777777777774
4777777777777774
4444444444444444
CCCCCCCCCCCCCCCC
CCCCCCCCCCCCCCCC
CDDDDDDDDDDDDDDC
CDDDDDDDDDDDDDDC
CDDDDDDDDDDDDDDC
CDDDDDDDDDDDDDDC
CDDDDDDDDDDDDDDC
CDDDDDDDDDDDDDDC
CDDDDDDDDDDDDDDC
CCCCCCCCCCCCCCCC
4..............4
4..............4

# 7: Kitchen Counter & Sink
@SPRITE 7
6666666666666666
6666666666666666
6666000000666666
66660CCCC0666666
66660CCCC0666666
6666000000666666
6666666666666666
5555555555555555
4444444444444444
4444444444444444
4444444444444444
4444444444444444
4444444444444444
4444444444444444
0000000000000000
................

# 8: Stairs Up (1F -> 2F)
@SPRITE 8
0000000000000000
0777777777777770
0555555555555550
0666666666666660
0555555555555550
0666666666666660
0555555555555550
0666666666666660
0555555555555550
0666666666666660
0555555555555550
0666666666666660
0555555555555550
0666666666666660
0555555555555550
0000000000000000

# 9: Stairs Down (2F -> 1F)
@SPRITE 9
0000000000000000
0111111111111110
0000000000000000
0222222222222220
0000000000000000
0555555555555550
0000000000000000
0666666666666660
0000000000000000
0777777777777770
0000000000000000
0666666666666660
0000000000000000
0555555555555550
0000000000000000
0000000000000000

# 10: Vinyl Record Sprite
@SPRITE 10
.....000000.....
...0055555500...
..055000000550..
.05505555550550.
.05055777755050.
0550577007750550
0550570000750550
0550570000750550
0550577007750550
.05055777755050.
.05505555550550.
..055000000550..
...0055555500...
.....000000.....
................
................

# 11: Sofa
@SPRITE 11
................
.CCCCCCCCCCCCCC.
.CDDDDDDDDDDDDC.
.CDDDDDDDDDDDDC.
.CDDDDDDDDDDDDC.
.CDDDDDDDDDDDDC.
.CCCCCCCCCCCCCC.
.CCCCCCCCCCCCCC.
.CDDDDDDDDDDDDC.
.CDDDDDDDDDDDDC.
.CDDDDDDDDDDDDC.
.CDDDDDDDDDDDDC.
.CCCCCCCCCCCCCC.
.00000000000000.
.4............4.
................

# 12: House Plant
@SPRITE 12
......3BB3......
....33BBBB33....
...3BBBBBBBB3...
...3BB3333BB3...
....3BBBBBB3....
.....33BB33.....
......4444......
......4444......
.....999999.....
.....999999.....
.....999999.....
.....999999.....
......9999......
......9999......
.......00.......
................

# 13: Coffee Table
@SPRITE 13
................
................
................
................
4444444444444444
4FFFFFFFFFFFFFF4
4FFFFFFFFFFFFFF4
4FFFFFFFFFFFFFF4
4444444444444444
.00000000000000.
.4............4.
.4............4.
.4............4.
.4............4.
................
................

# 14: Player Down 1
@SPRITE 14
.....000000.....
....04444440....
....04FFFF40....
....04F00F40....
....04FFFF40....
....04FFFF40....
.....000000.....
....08888880....
...0888888880...
...0888888880...
...0888888880...
....08888880....
....01100110....
....01100110....
....05500550....
................

# 15: Player Down 2 (Walk)
@SPRITE 15
.....000000.....
....04444440....
....04FFFF40....
....04F00F40....
....04FFFF40....
....04FFFF40....
.....000000.....
....08888880....
...0888888880...
...0888888880...
....08888880....
....01100110....
....0110.0110...
....0550..0550..
................
................

# 16: Player Up 1
@SPRITE 16
.....000000.....
....04444440....
....04444440....
....04444440....
....04444440....
....04444440....
.....000000.....
....08888880....
...0888888880...
...0888888880...
...0888888880...
....08888880....
....01100110....
....01100110....
....05500550....
................

# 17: Player Up 2 (Walk)
@SPRITE 17
.....000000.....
....04444440....
....04444440....
....04444440....
....04444440....
....04444440....
.....000000.....
....08888880....
...0888888880...
...0888888880...
....08888880....
....01100110....
...0110..0110...
...0550...0550..
................
................

# 18: Player Left 1
@SPRITE 18
.....000000.....
....04444440....
...04FFFF440....
...04F0FF440....
...04FFFF440....
...04FFFF440....
.....000000.....
...00888880.....
..088888880.....
..088888880.....
...08888880.....
....0111110.....
....0110110.....
....0110.00.....
....0550........
................

# 19: Player Left 2 (Walk)
@SPRITE 19
.....000000.....
....04444440....
...04FFFF440....
...04F0FF440....
...04FFFF440....
...04FFFF440....
.....000000.....
...00888880.....
..088888880.....
..088888880.....
...08888880.....
....0111110.....
...0110.0110....
...0550..0550...
................
................

# 20: Player Right 1
@SPRITE 20
.....000000.....
....04444440....
....044FFFF40...
....044FF0F40...
....044FFFF40...
....044FFFF40...
.....000000.....
.....08888800...
.....088888880..
.....088888880..
.....08888880...
.....0111110....
.....0110110....
.....00.0110....
........0550....
................

# 21: Player Right 2 (Walk)
@SPRITE 21
.....000000.....
....04444440....
....044FFFF40...
....044FF0F40...
....044FFFF40...
....044FFFF40...
.....000000.....
.....08888800...
.....088888880..
.....088888880..
.....08888880...
.....0111110....
....0110.0110...
...0550..0550...
................
................

# 22: Garden Grass
@SPRITE 22
3333333333333333
33B33333333B3333
3333333333333333
333333B333333333
3333333333333333
33B33333333B3333
3333333333333333
3333333333333333
333333B333333333
3333333333333333
33B33333333B3333
3333333333333333
3333333333333333
333333B333333333
3333333333333333
3333333333333333

# 23: Balcony / Terrace Stone Tile
@SPRITE 23
6666666666666666
6555555665555556
6577775665777756
6577775665777756
6577775665777756
6555555665555556
6666666666666666
6666666666666666
6555555665555556
6577775665777756
6577775665777756
6577775665777756
6555555665555556
6666666666666666
6666666666666666
6666666666666666

# ==============================================================================
# WORLD TILEMAP (48 x 32 tiles)
# Row 0..15 : 2nd Floor (Bed Room | Study / Loft | Balcony)
# Row 16..31: 1st Floor (Kitchen  | Living Room  | Garden)
# ==============================================================================
@MAP 0 0
2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2
3 4 3 3 4 3 3 4 3 3 4 3 3 4 3 2 3 5 5 3 4 3 3 4 3 3 4 3 5 5 3 2 3 4 3 4 3 4 3 4 3 4 3 4 3 4 3 2
3 6 6 1 1 1 1 1 1 1 1 1 1 C 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2
3 6 6 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2
3 1 1 1 1 D 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 D 1 1 1 1 3 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 9 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2
3 1 1 1 1 1 1 1 1 1 1 1 1 C 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 C 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 C 3 2
2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2
3 7 7 7 7 3 3 4 3 3 4 3 3 4 3 2 3 4 3 3 4 3 3 8 3 3 4 3 3 4 3 2 3 4 3 4 3 4 3 4 3 4 3 4 3 4 3 2
3 7 7 7 7 1 1 1 1 1 1 1 1 C 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 C 3 2 M M M M M M M M M M M M M M M 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 M M M M M M M M M M M M M M M 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 B B 1 1 1 1 1 1 B B 1 3 2 M M M M M M M M M M M M M M M 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 B B 1 1 1 1 1 1 B B 1 3 2 M M M M M M M M M M M M M M M 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 M 2
3 1 1 1 D 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 M 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 M M M M M M M M M M M M M M M 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 M M M M M M M M M M M M M M M 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 M M M M M M M M M M D M M M M 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 M M M M M M M M M M M M M M M 2
3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 M M M M M M M M M M M M M M M 2
3 1 1 1 1 1 1 1 1 1 1 1 1 C 3 2 3 1 1 1 1 1 1 1 1 1 1 1 1 C 3 2 M M M M M M M M M M M M M M C 2
2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2
