# ============================================================
#  DUCK TREASURE (あひるの海底宝探し大冒険)
#  Usakame Engine / mrubyedge
# ============================================================

# --- Game State Initialization ---
def init_game
  $state = :title     # :title, :play, :gameover, :clear
  $tick = 0
  $score = 0
  $depth_record = 0

  # Player Duck
  $px = 120.0
  $py = 28.0
  $vx = 0.0
  $vy = 0.0
  $hp = 100.0
  $max_hp = 100.0
  $air = 100.0
  $max_air = 100.0
  $facing_left = false
  $inv_timer = 0
  $quack_timer = 0

  # Relics
  $has_anchor = false
  $has_crown = false
  $has_pearl = false

  # World dimensions
  $world_w = 256
  $world_h = 1400

  # Particle list
  $particles = []

  # Generate Sea Items & Creatures
  init_world_objects
end

def init_world_objects
  $bubbles = []
  $coins = []
  $gems = []
  $jellyfish = []
  $sharks = []
  $seaweeds = []

  # Seaweeds on sides & platforms
  i = 0
  while i < 30
    wx = (i % 2 == 0) ? rand(6..24) : rand(220..244)
    wy = rand(80..1350)
    $seaweeds << { x: wx, y: wy, h: rand(20..40), phase: rand(100) }
    i += 1
  end

  # Ambient rising bubbles
  i = 0
  while i < 18
    $bubbles << {
      x: rand(16..240).to_f,
      y: rand(100..1380).to_f,
      vy: -(0.5 + rand() * 0.8),
      size: rand(2..4)
    }
    i += 1
  end

  # Coins (Shallow to mid depths)
  i = 0
  while i < 28
    $coins << {
      x: rand(24..232),
      y: rand(70..800),
      taken: false
    }
    i += 1
  end

  # Gems (Deeper, worth more)
  i = 0
  while i < 16
    $gems << {
      x: rand(24..232),
      y: rand(450..1350),
      taken: false
    }
    i += 1
  end

  # Jellyfish (Vertical wanderers)
  i = 0
  while i < 9
    jy = 160 + i * 120
    $jellyfish << {
      x: rand(30..220).to_f,
      base_y: jy.to_f,
      y: jy.to_f,
      phase: rand(360).to_f,
      spd: 0.02 + rand() * 0.02
    }
    i += 1
  end

  # Sharks (Horizontal predators in the dark abyss)
  i = 0
  while i < 6
    sy = 650 + i * 110
    dir = (i % 2 == 0) ? 1.0 : -1.0
    $sharks << {
      x: rand(30..220).to_f,
      y: sy.to_f,
      vx: dir * (0.8 + rand() * 0.6),
      dir: dir
    }
    i += 1
  end

  # The 3 Ancient Relics!
  $relic_anchor = { x: 120, y: 460, taken: false }
  $relic_crown  = { x: 40,  y: 920, taken: false }
  $relic_pearl  = { x: 200, y: 1330, taken: false }
end

# --- Particle Spawner ---
def spawn_bubbles(x, y, count)
  c = 0
  while c < count
    $particles << {
      x: x + rand(-4..4).to_f,
      y: y + rand(-4..4).to_f,
      vx: rand(-0.4..0.4).to_f,
      vy: -(0.6 + rand() * 1.2),
      life: rand(20..40),
      col: (rand(2) == 0 ? 7 : 12)
    }
    c += 1
  end
end

def spawn_splash(x, y)
  c = 0
  while c < 12
    $particles << {
      x: x + rand(-8..8).to_f,
      y: y + rand(-2..2).to_f,
      vx: rand(-1.2..1.2).to_f,
      vy: -(1.0 + rand() * 1.5),
      life: rand(15..28),
      col: 7
    }
    c += 1
  end
end

# --- Update Loop ---
def update
  $tick += 1

  if $state == :title
    update_title
  elsif $state == :play
    update_play
  elsif $state == :gameover || $state == :clear
    update_ended
  end
end

def update_title
  # Start game on Action A (Z/Space) or Action B (X/Enter)
  if btn(4) || btn(5)
    init_world_objects
    $px = 120.0
    $py = 28.0
    $vx = 0.0
    $vy = 0.0
    $hp = 100.0
    $air = 100.0
    $score = 0
    $has_anchor = false
    $has_crown = false
    $has_pearl = false
    $state = :play
  end
end

def update_ended
  # Press Z to play again
  if ($tick % 60 > 15) && (btn(4) || btn(5))
    init_game
    $state = :play
  end
end

def update_play
  $inv_timer -= 1 if $inv_timer > 0
  $quack_timer -= 1 if $quack_timer > 0

  # Quack action (Action B)
  if btn(5) && $quack_timer <= 0
    $quack_timer = 25
    spawn_bubbles($px + 8.0, $py + 4.0, 5)
  end

  # Controls
  speed = 0.35
  boost = btn(4) ? 1.6 : 1.0 # Z = Swim faster kick!
  accel = speed * boost

  in_water = $py > 32.0

  if btn(0) # Left
    $vx = $vx - accel
    $facing_left = true
  end
  if btn(1) # Right
    $vx = $vx + accel
    $facing_left = false
  end
  if btn(2) # Up
    $vy = $vy - accel
  end
  if btn(3) # Down
    $vy = $vy + accel
  end

  # Buoyancy & Water physics
  if in_water
    # Water friction
    $vx = $vx * 0.88
    $vy = $vy * 0.88
    # Gentle natural buoyancy (duck naturally floats towards surface)
    $vy = $vy - 0.06

    # Turbo boost costs extra air
    if btn(4) && (btn(0) || btn(1) || btn(2) || btn(3))
      $air = $air - 0.08
      if $tick % 4 == 0
        spawn_bubbles($px + ($facing_left ? 14.0 : 2.0), $py + 10.0, 1)
      end
    end

    # Natural underwater air consumption
    $air = $air - 0.05
    if $air < 0.0
      $air = 0.0
      # Drowning damage!
      $hp = $hp - 0.35
    end
  else
    # Above or at surface
    $vx = $vx * 0.85
    $vy = $vy * 0.80
    # Gravity back to water
    $vy = $vy + 0.15

    # Refill oxygen rapidly at surface!
    if $air < $max_air
      $air = $air + 1.2
      $air = $max_air if $air > $max_air
    end

    # Clamp surface jump
    if $py < 16.0
      $py = 16.0
      $vy = 0.0
    end
  end

  # Water boundary crossing splash
  prev_y = $py
  $px = $px + $vx
  $py = $py + $vy

  # Surface splash transition
  if (prev_y <= 32.0 && $py > 32.0) || (prev_y > 32.0 && $py <= 32.0)
    spawn_splash($px + 8.0, 32.0)
  end

  # Clamp within screen world boundaries
  $px = 8.0 if $px < 8.0
  $px = 232.0 if $px > 232.0
  $py = $world_h - 20.0 if $py > ($world_h - 20.0)

  # Record depth
  curr_depth = (($py - 32.0) / 10.0).to_i
  curr_depth = 0 if curr_depth < 0
  $depth_record = curr_depth if curr_depth > $depth_record

  # Ambient bubbles update
  $bubbles.each do |b|
    b[:y] = b[:y] + b[:vy]
    b[:x] = b[:x] + (Math.sin(($tick + b[:y]) * 0.05) * 0.3)
    if b[:y] < 34.0
      b[:y] = $world_h - rand(10..30).to_f
      b[:x] = rand(16..240).to_f
    end

    # Duck catches oxygen bubble!
    dx = ($px + 8.0) - b[:x]
    dy = ($py + 8.0) - b[:y]
    if (dx * dx + dy * dy) < 144.0 && in_water
      $air = $air + 12.0
      $air = $max_air if $air > $max_air
      $score += 10
      spawn_bubbles(b[:x], b[:y], 6)
      b[:y] = $world_h - rand(10..30).to_f
      b[:x] = rand(16..240).to_f
    end
  end

  # Coins collection
  $coins.each do |c|
    next if c[:taken]
    dx = ($px + 8.0) - (c[:x] + 8.0)
    dy = ($py + 8.0) - (c[:y] + 8.0)
    if (dx * dx + dy * dy) < 160.0
      c[:taken] = true
      $score += 100
      spawn_bubbles(c[:x] + 8.0, c[:y] + 8.0, 5)
    end
  end

  # Gems collection
  $gems.each do |g|
    next if g[:taken]
    dx = ($px + 8.0) - (g[:x] + 8.0)
    dy = ($py + 8.0) - (g[:y] + 8.0)
    if (dx * dx + dy * dy) < 160.0
      g[:taken] = true
      $score += 500
      spawn_bubbles(g[:x] + 8.0, g[:y] + 8.0, 8)
    end
  end

  # Relics collection
  if !$relic_anchor[:taken]
    dx = ($px + 8.0) - ($relic_anchor[:x] + 8.0)
    dy = ($py + 8.0) - ($relic_anchor[:y] + 8.0)
    if (dx * dx + dy * dy) < 200.0
      $relic_anchor[:taken] = true
      $has_anchor = true
      $score += 2000
      spawn_bubbles($relic_anchor[:x] + 8.0, $relic_anchor[:y] + 8.0, 15)
    end
  end

  if !$relic_crown[:taken]
    dx = ($px + 8.0) - ($relic_crown[:x] + 8.0)
    dy = ($py + 8.0) - ($relic_crown[:y] + 8.0)
    if (dx * dx + dy * dy) < 200.0
      $relic_crown[:taken] = true
      $has_crown = true
      $score += 3000
      spawn_bubbles($relic_crown[:x] + 8.0, $relic_crown[:y] + 8.0, 15)
    end
  end

  if !$relic_pearl[:taken]
    dx = ($px + 8.0) - ($relic_pearl[:x] + 8.0)
    dy = ($py + 8.0) - ($relic_pearl[:y] + 8.0)
    if (dx * dx + dy * dy) < 200.0
      $relic_pearl[:taken] = true
      $has_pearl = true
      $score += 5000
      spawn_bubbles($relic_pearl[:x] + 8.0, $relic_pearl[:y] + 8.0, 20)
    end
  end

  # Jellyfish movement & collision
  $jellyfish.each do |j|
    j[:phase] = j[:phase] + j[:spd]
    j[:y] = j[:base_y] + Math.sin(j[:phase]) * 24.0

    if $inv_timer <= 0
      dx = ($px + 8.0) - (j[:x] + 8.0)
      dy = ($py + 8.0) - (j[:y] + 8.0)
      if (dx * dx + dy * dy) < 140.0
        $hp = $hp - 16.0
        $inv_timer = 45
        # Electrical knockback
        $vy = $vy - 2.5
        spawn_bubbles($px + 8.0, $py + 8.0, 8)
      end
    end
  end

  # Sharks movement & collision
  $sharks.each do |s|
    s[:x] = s[:x] + s[:vx]
    if s[:x] < 16.0
      s[:x] = 16.0
      s[:vx] = s[:vx].abs
      s[:dir] = 1.0
    elsif s[:x] > 224.0
      s[:x] = 224.0
      s[:vx] = -s[:vx].abs
      s[:dir] = -1.0
    end

    if $inv_timer <= 0
      dx = ($px + 8.0) - (s[:x] + 8.0)
      dy = ($py + 8.0) - (s[:y] + 8.0)
      if (dx * dx + dy * dy) < 180.0
        $hp = $hp - 28.0
        $inv_timer = 50
        $vx = s[:dir] * 3.5
        $vy = $vy - 2.0
        spawn_bubbles($px + 8.0, $py + 8.0, 12)
      end
    end
  end

  # Update particles
  $particles.each do |p|
    p[:x] = p[:x] + p[:vx]
    p[:y] = p[:y] + p[:vy]
    p[:life] = p[:life] - 1
  end
  $particles.reject! { |p| p[:life] <= 0 }

  # Check Game Over
  if $hp <= 0.0
    $hp = 0.0
    $state = :gameover
  end

  # Check Game Clear: Has all 3 relics & returned to surface safely!
  if $has_anchor && $has_crown && $has_pearl && $py <= 30.0
    $state = :clear
    $score += 5000 # Surface survival bonus!
  end
end

# --- Drawing Section ---
def draw
  cls(1) # Default deep water clear

  if $state == :title
    draw_title
    return
  end

  # Camera follows duck vertically
  target_cam_y = $py - 120.0
  target_cam_y = 0.0 if target_cam_y < 0.0
  max_cam_y = ($world_h - 256).to_f
  target_cam_y = max_cam_y if target_cam_y > max_cam_y
  cam_y = target_cam_y.to_i

  camera(0, cam_y)

  # Draw Sky & Surface
  draw_sky_and_shallows

  # Draw Sea Background & Gradients
  draw_ocean_depths

  # Draw Seaweeds
  draw_seaweeds

  # Draw Relics
  draw_relics

  # Draw Collectibles
  $coins.each do |c|
    spr("🪙", c[:x], c[:y]) unless c[:taken]
  end

  $gems.each do |g|
    spr("💎", g[:x], g[:y]) unless g[:taken]
  end

  # Draw Rising Oxygen Bubbles
  $bubbles.each do |b|
    circfill(b[:x].to_i, b[:y].to_i, b[:size], 12)
    circ(b[:x].to_i, b[:y].to_i, b[:size], 7)
    pset(b[:x].to_i - 1, b[:y].to_i - 1, 7)
  end

  # Draw Creatures
  $jellyfish.each do |j|
    spr("🪼", j[:x].to_i, j[:y].to_i)
  end

  $sharks.each do |s|
    spr("🦈", s[:x].to_i, s[:y].to_i, s[:dir] < 0.0, false)
  end

  # Draw Particles
  $particles.each do |p|
    pset(p[:x].to_i, p[:y].to_i, p[:col])
  end

  # Draw Seabed
  draw_seabed

  # Draw Player Duck
  draw_duck

  # UI Overlay (Ignore camera offset)
  camera(0, 0)
  draw_hud

  if $state == :gameover
    draw_gameover_modal
  elsif $state == :clear
    draw_clear_modal
  end
end

def draw_sky_and_shallows
  # Sky
  rectfill(0, 0, 256, 32, 12)
  # Clouds
  circfill(40, 14, 10, 7)
  circfill(52, 12, 12, 7)
  circfill(64, 14, 9, 7)
  circfill(180, 10, 12, 7)
  circfill(195, 8, 14, 7)

  # Sun
  circfill(230, 16, 12, 10)
  circfill(230, 16, 9, 9)

  # Water Surface Waves
  wave_off = ($tick * 0.08)
  x = 0
  while x < 256
    wy = 31 + (Math.sin(wave_off + x * 0.15) * 2.0).to_i
    line(x, wy, x, 36, 7)
    pset(x, wy - 1, 12)
    x += 1
  end
end

def draw_ocean_depths
  # Depth Color Gradient Bands
  # 36..400: Sunlit Shallow Water (Blue / Cyan)
  rectfill(0, 36, 256, 364, 12)

  # Sun rays filtering through shallows
  r = 0
  while r < 6
    rx = 20 + r * 42 + (Math.sin(($tick + r * 30) * 0.03) * 12.0).to_i
    line(rx, 36, rx + 25, 260, 7)
    r += 1
  end

  # Dither transition from 360 to 440 (Shallow -> Twilight)
  rectfill(0, 420, 256, 430, 1) # Dark Blue
  rectfill(0, 850, 256, 550, 0) # Midnight Abyss (Black)

  # Subtle ocean depth markers on left side
  d = 100
  while d <= 1300
    line(0, d, 14, d, 5)
    print_text("#{d / 10}m", 16, d - 3, 5)
    d += 200
  end
end

def draw_seaweeds
  $seaweeds.each do |sw|
    sw_h = sw[:h]
    base_x = sw[:x]
    base_y = sw[:y]
    sy = 0
    while sy < sw_h
      sway = (Math.sin(($tick * 0.04) + sw[:phase] + (sy * 0.1)) * 4.0).to_i
      pset(base_x + sway, base_y - sy, 3)
      pset(base_x + sway + 1, base_y - sy, 11)
      sy += 2
    end
  end
end

def draw_relics
  # Golden Anchor
  if !$relic_anchor[:taken]
    spr("⚓", $relic_anchor[:x], $relic_anchor[:y])
    if ($tick % 30) < 15
      pset($relic_anchor[:x] + 14, $relic_anchor[:y] + 2, 7)
    end
  end

  # Royal Crown
  if !$relic_crown[:taken]
    spr("👑", $relic_crown[:x], $relic_crown[:y])
    if ($tick % 24) < 12
      pset($relic_crown[:x] + 12, $relic_crown[:y] + 2, 10)
    end
  end

  # Star Pearl
  if !$relic_pearl[:taken]
    spr("⭐", $relic_pearl[:x], $relic_pearl[:y])
    circ($relic_pearl[:x] + 8, $relic_pearl[:y] + 8, 10, ($tick % 16 < 8 ? 7 : 10))
  end
end

def draw_seabed
  # Rocky sandy bottom
  rectfill(0, 1370, 256, 30, 4) # Brown rocks
  rectfill(0, 1385, 256, 15, 5) # Dark stones

  # Sea floor details
  i = 0
  while i < 16
    bx = i * 16 + 4
    circfill(bx, 1374, 5, 5)
    pset(bx + 2, 1372, 6)
    i += 1
  end
end

def draw_duck
  # Invincibility blink
  return if $inv_timer > 0 && ($inv_timer % 4 < 2)

  dx = $px.to_i
  dy = $py.to_i

  # Quack emote text
  if $quack_timer > 0
    print_text("QUACK!", dx - 8, dy - 12, 10)
  end

  # Duck emoji sprite
  spr("🦆", dx, dy, $facing_left, false)

  # Water wake / ripples when swimming
  if $py <= 34.0
    line(dx - 3, 33, dx + 18, 33, 7)
  end
end

def draw_hud
  # Top banner background bar
  rectfill(0, 0, 256, 20, 0)
  line(0, 20, 256, 20, 5)

  # Health Bar (HP)
  print_text("HP", 4, 3, 8)
  rect(18, 3, 44, 6, 7)
  hp_w = (($hp / $max_hp) * 42.0).to_i
  hp_w = 0 if hp_w < 0
  rectfill(19, 4, hp_w, 4, 8)

  # Oxygen Bar (AIR)
  print_text("AIR", 66, 3, 12)
  rect(86, 3, 44, 6, 7)
  air_w = (($air / $max_air) * 42.0).to_i
  air_w = 0 if air_w < 0
  air_col = ($air < 25.0 && ($tick % 16 < 8)) ? 8 : 12
  rectfill(87, 4, air_w, 4, air_col)

  # Current Depth
  curr_depth = (($py - 32.0) / 10.0).to_i
  curr_depth = 0 if curr_depth < 0
  print_text("#{curr_depth}m", 136, 3, 10)

  # Score
  print_text("SC:#{$score}", 180, 3, 7)

  # Relic icons collected in top right
  print_text("RELICS:", 4, 11, 6)
  if $has_anchor
    spr("⚓", 46, 10, false, false, 0, 0.6)
  else
    print_text("-", 48, 11, 5)
  end

  if $has_crown
    spr("👑", 62, 10, false, false, 0, 0.6)
  else
    print_text("-", 64, 11, 5)
  end

  if $has_pearl
    spr("⭐", 78, 10, false, false, 0, 0.6)
  else
    print_text("-", 80, 11, 5)
  end

  # Objective helper hint
  if !$has_anchor || !$has_crown || !$has_pearl
    print_text("FIND 3 RELICS & RETURN!", 100, 11, 14)
  else
    # All 3 relics acquired!
    swim_col = ($tick % 16 < 8) ? 11 : 7
    print_text("ALL RELICS! SWIM TO SURFACE!", 94, 11, swim_col)
  end

  # Low Air Warning flashing
  if $air < 20.0 && $py > 32.0 && ($tick % 20 < 10)
    rectfill(68, 28, 120, 14, 8)
    print_text("! NEED AIR ! SURFACE !", 72, 31, 7)
  end
end

def draw_title
  # Title Background: Cheerful ocean surface & deep sea
  rectfill(0, 0, 256, 100, 12)
  rectfill(0, 100, 256, 156, 1)

  # Sun & Clouds
  circfill(210, 30, 20, 10)
  circfill(40, 28, 16, 7)
  circfill(60, 24, 20, 7)
  circfill(80, 28, 16, 7)

  # Surface wave
  x = 0
  while x < 256
    wy = 98 + (Math.sin(($tick * 0.05) + x * 0.1) * 3.0).to_i
    line(x, wy, x, 104, 7)
    x += 1
  end

  # Giant Title Box
  rectfill(20, 36, 216, 52, 0)
  rect(20, 36, 216, 52, 10)
  rect(22, 38, 212, 48, 7)

  print_text("DUCK TREASURE", 54, 46, 10)
  print_text("~ UNDERWATER ODYSSEY ~", 42, 60, 7)
  print_text("あひるの海底宝探し大冒険", 46, 74, 11)

  # Cute swimming duck demo
  duck_y = 100 + (Math.sin($tick * 0.08) * 4.0).to_i
  spr("🦆", 116, duck_y)
  spr("🫧", 136, duck_y - 6)

  # Relic display
  spr("⚓", 50, 145)
  spr("👑", 120, 145)
  spr("⭐", 190, 145)

  # Instructions
  rectfill(30, 172, 196, 42, 0)
  rect(30, 172, 196, 42, 6)
  print_text("ARROWS : DIVE & SWIM", 52, 178, 7)
  print_text("Z/SPACE: PADDLE BOOST", 52, 189, 7)
  print_text("X/ENTER: QUACK / BUBBLE", 48, 200, 7)

  # Prompt
  if ($tick % 60) < 36
    print_text("PRESS [Z] OR [SPACE] TO START!", 36, 228, 10)
  end
end

def draw_gameover_modal
  rectfill(38, 80, 180, 96, 0)
  rect(38, 80, 180, 96, 8)
  rect(40, 82, 176, 92, 2)

  print_text("GAME OVER", 94, 94, 8)
  print_text("The duck ran out of energy...", 48, 110, 6)
  print_text("MAX DEPTH: #{$depth_record}m", 80, 126, 10)
  print_text("SCORE    : #{$score}", 80, 138, 7)

  if ($tick % 50) < 30
    print_text("PRESS [Z] TO RETRY", 70, 156, 14)
  end
end

def draw_clear_modal
  rectfill(32, 60, 192, 136, 0)
  rect(32, 60, 192, 136, 10)
  rect(34, 62, 188, 132, 7)

  print_text("★ TREASURE MASTER! ★", 56, 74, 10)
  print_text("All 3 Ancient Relics Recovered!", 42, 90, 11)

  spr("⚓", 74, 106)
  spr("👑", 120, 106)
  spr("⭐", 166, 106)

  print_text("FINAL SCORE : #{$score}", 68, 132, 7)
  print_text("MAX DEPTH   : #{$depth_record}m", 68, 144, 12)

  # Rank calculation
  rank = "B"
  rank = "A" if $score >= 12000
  rank = "S (LEGEND DUCK!)" if $score >= 16000
  print_text("RANK: #{rank}", 68, 158, 10)

  if ($tick % 50) < 30
    print_text("PRESS [Z] TO PLAY AGAIN", 58, 178, 14)
  end
end

# Initial trigger
init_game
