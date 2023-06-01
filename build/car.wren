var WIDTH = 800
var HEIGHT = 450

var FRAME = 0
var MAP_BOUNDS = Vector.new(1200, 1000)
var CAR = null
var CAMERA = Vector.ZERO
var CAMERA_FORWARD_OFFSET = 40
var CAMERA_SMOOTHING = 0.2

var SCREENSHAKE_TIME = 0.15
var SCREENSHAKE_STRENGTH = 6

var GROUND_SURFACE = null
var GROUND_COLOR = 40
var GROUND_NOISE = 5

var TITLE_SURFACE = null

// Images
var IMAGE_CASING = Surface.new_from_png("casing.png")
var TUTORIAL = Surface.new_from_png("tutorial.png")

// Colors
var COLOR_HP = Color.new(255, 80, 100)
var COLOR_CYAN = Color.new(128, 225, 255)
var COLOR_YELLOW = Color.new(255, 180, 0)

// Keys
var KEY_UP = Input.get_keycode("W")
var KEY_DOWN = Input.get_keycode("S")
var KEY_LEFT = Input.get_keycode("A")
var KEY_RIGHT = Input.get_keycode("D")
var KEY_RESTART = Keycodes.SPACE
var MOUSE_TP = Input.button_mouse_right
var MOUSE_SHOOT = Input.button_mouse_left

// Alternate keys
var KEY_UP_ALT = Keycodes.UP
var KEY_DOWN_ALT = Keycodes.DOWN
var KEY_LEFT_ALT = Keycodes.LEFT
var KEY_RIGHT_ALT = Keycodes.RIGHT
var KEY_UP_FR = Input.get_keycode("Z")
var KEY_LEFT_FR = Input.get_keycode("Q")

// Sounds
var SOUND_EXPLOSION = Sound.load_ogg("boom.ogg")
var SOUND_NUKE_INCOMING = Sound.load_ogg("nuke.ogg")
var SOUND_TP = Sound.load_ogg("tp.ogg")
var SOUND_NUKE = Sound.load_ogg("expl.ogg")
class ProgressBar {
    value { _value }
    value=(v) { _value = v.clamp(_min, _max) }

    construct new(border_color, fill_color, min, max, value, width, height) {
        _border_color = border_color
        _fill_color = fill_color
        _min = min
        _max = max
        _value = value.clamp(min, max)
        _width = width
        _height = height
    }

    construct new(color, min, max, value, width, height) {
        _border_color = color
        _fill_color = color
        _min = min
        _max = max
        _value = value.clamp(min, max)
        _width = width
        _height = height
    }

    is_full { (_max - _value).abs <= 1e-10 }
    is_empty { (_min - _value).abs <= 1e-10 }

    fill() {
        _value = _max
    }

    empty() {
        _value = _min
    }

    draw(x, y) {
        Draw.rectangle(x, y, _width, _height, _border_color, false)
        var filled_width = Math.map_clamped(_value, _min, _max, 0, _width)
        Draw.rectangle(x, y, filled_width, _height, _fill_color, true)
    }

    draw(pos) {
        draw(pos.x, pos.y)
    }

    draw_centered(y) {
        var x = WIDTH / 2 - _width / 2
        draw(x, y)
    }
}
class Entity {
    is_dead { _is_dead }

    tick(dt) {
    }

    render() {
    }

    kill() {
        _is_dead = true
    }
}
class Explosion is Entity {
    max_radius { 26 }
    radius_step { 200 }

    construct new(pos) {
        _pos = pos

        _radius = 0
        _white_color = Color.WHITE
        _yellow_color = Color.new(
            COLOR_YELLOW.r,
            COLOR_YELLOW.g,
            COLOR_YELLOW.b
        )

        scorch_ground()
    }

    scorch_ground() {
        Surface.set_target(GROUND_SURFACE)
            for (r in 0..max_radius) {
                var streak_color = Color.BLACK
                streak_color.a = Math.map(
                    r,
                    0, max_radius,
                    180, 60
                )

                var size = 2 + Random.rand() * 4
                var offset = Vector.RIGHT.rotated(Random.rand() * Num.pi * 2) * r

                Draw.circle(
                    _pos + offset,
                    size, streak_color, true
                )
            }
        Surface.reset_target()
    }

    tick(dt) {
        _radius = (_radius + radius_step * dt).min(max_radius + 1)
        var alpha = Math.map(
            _radius,
            0, max_radius,
            255, 128
        )

        _white_color.a = alpha
        _yellow_color.a = alpha

        if (_radius > max_radius) {
            kill()
        }
    }

    render() {
        var cam_adjusted_pos = _pos - CAMERA

        Draw.circle(cam_adjusted_pos, 26 - _radius, _white_color, true)
        Draw.circle(cam_adjusted_pos, _radius, _yellow_color, true)
    }
}

class Flash is Entity {
    lifetime { 0.2 }

    construct new(color) {
        _color = Color.new(color.r, color.g, color.b)
        _timer = lifetime
    }

    tick(dt) {
        _timer = _timer - dt
        var alpha = Math.map(
            _timer,
            lifetime, 0,
            255, 0
        )
        _color.a = alpha

        if (_timer <= 0) {
            kill()
        }
    }

    render() {
        Draw.rectangle(0, 0, WIDTH, HEIGHT, _color, true)
    }
}

class PopupText is Entity {
    construct new(message, pos, velocity, lifetime) {
        _msg = message
        _pos = pos
        _vel = velocity
        _timer = lifetime
    }

    tick(dt) {
        _timer = _timer - dt
        if (_timer <= 0) {
            kill()
        }

        _pos = _pos + _vel * dt
    }

    render() {
        if (FRAME % 20 < 15) {
            Draw.text(_pos, _msg, COLOR_CYAN)
        }
    }
}

class TeleportStreak is Entity {
    lifetime { 0.3 }

    construct new(start, end) {
        _start = start
        _end = end
        _timer = lifetime
    }

    tick(dt) {
        _timer = _timer - dt

        if (_timer <= 0) {
            kill()
        }
    }

    render() {
        var color = Color.WHITE
        var ground_color = Color.BLACK
        ground_color.a = 10
        color.a = Math.map(_timer, lifetime, 0, 255, 0)

        var step = 4
        var local_y = (_end - _start).normalized
        var local_x = local_y.rotated(Num.pi/2)
        for (i in -4..4) {
            var offset = local_x * i * (step * Random.rand())
            offset = offset + local_y * Random.rand() * 10 * (-i.abs)
            offset = offset + Vector.new(Random.rand(), Random.rand())
            Draw.line(_start - CAMERA + offset, _end - CAMERA + offset, color)

            Surface.set_target(GROUND_SURFACE)
                Draw.line(_start + offset, _end + offset, ground_color)
            Surface.reset_target()
        }
    }
}
var BULLET_SPRITE = Surface.new_from_png("bullet.png")

class Bullet is Entity {
    speed { 1200 }
    size { 6 }

    angle_jitter { 0.05 }
    speed_jitter { 100 }

    construct new(pos, angle) {
        var real_angle = angle + (Random.rand() * angle_jitter * 2 - angle_jitter)
        var real_speed = Random.irange(speed - speed_jitter, speed + speed_jitter)
        _pos = pos
        _angle = real_angle
        _vel = Vector.RIGHT.rotated(real_angle) * real_speed
    }

    tick(dt) {
        _pos = _pos + _vel * dt
        if (_pos.x < -size || _pos.x > MAP_BOUNDS.x + size ||
            _pos.y < -size || _pos.y > MAP_BOUNDS.y + size) {
            kill()
        } else {
            var killed = Game.kill_enemy_at(_pos, size + 10)
            if (killed) {
                kill()
            }
        }
    }

    render() {
        var cam_adjusted_pos = _pos - CAMERA
        Surface.draw_angle(BULLET_SPRITE, cam_adjusted_pos, _angle)
    }
}
class TurretStats {
    static NORMAL { TurretStats.new("", 0.3, 1, 0) }
    static SHOTGUN { TurretStats.new("shotgun", 0.8, 3, Math.deg2rad(15)) }
    static MACHINEGUN { TurretStats.new("machine gun", 0.1, 1, 0) }
    static BROKEN { TurretStats.new("plasma railgun", 0.08, 2, Math.deg2rad(5)) }

    fire_rate { _fire_rate }
    bullet_count { _bullet_count }
    spread { _spread }
    name { _name }

    construct new(name, fire_rate, bullet_count, spread) {
        _name = name
        _fire_rate = fire_rate
        _bullet_count = bullet_count
        _spread = spread
    }
}

class Turret {
    barrel_offset { Vector.new(6, 0) }
    initial_upgrade_cost { 10 }
    upgrade_cost_increase { 5 }

    pos { _pos }
    pos=(v) { _pos = v }

    construct new(pos) {
        _upgrades = [
            TurretStats.NORMAL,
            TurretStats.SHOTGUN,
            TurretStats.MACHINEGUN,
            TurretStats.BROKEN
        ]
        _kills = 0
        _upgrade_cost = initial_upgrade_cost

        _sprite = Surface.new_from_png("turret.png")
        _shoot_sound = Sound.load_ogg("smg_fire.ogg")
        _pos = pos
        _angle = 0
        _lvl = 0
        _cooldown = 0
    }

    tick(dt) {
        _angle = (CAMERA + Input.mouse_pos() - _pos).angle

        if (_cooldown > 0) {
            _cooldown = _cooldown - dt
        } else {
            if (Input.get_mouse_button() == MOUSE_SHOOT) {
                Game.hide_title()
                shoot()
            }
        }
    }

    killed_enemy() {
        _kills = _kills + 1
        if (_kills >= _upgrade_cost) {
            upgrade()
        }
    }

    upgrade() {
        if (_lvl < _upgrades.count - 1) {
            _lvl = _lvl + 1
            _upgrade_cost = _upgrade_cost + upgrade_cost_increase
            _kills = 0

            var stats = _upgrades[_lvl]
            Game.spawn(PopupText.new(
                "Gun upgraded: %(stats.name) !",
                Vector.new(WIDTH / 2 - 80, 100),
                Vector.UP * 20,
                2.5
            ))
        }
    }

    shoot() {
        _shoot_sound.play(0.5, 0.75 + Random.rand()*0.25, 1.0)
        var stats = _upgrades[_lvl]
        var shoot_pos = _pos + barrel_offset.rotated(_angle)

        if (stats.bullet_count > 1) {
            var starting_angle = -stats.spread / 2
            var step = stats.spread / (stats.bullet_count - 1)
            for (i in 0...stats.bullet_count) {
                var angle_offset = starting_angle + i * step
                Game.spawn(Bullet.new(shoot_pos, _angle + angle_offset))
            }
        } else {
            var bullet = Bullet.new(shoot_pos, _angle)
            Game.spawn(bullet)
        }

        // draw shell casing
        Surface.set_target(GROUND_SURFACE)
            var v = (Vector.RIGHT * Random.rand() * 20).rotated(Random.rand() * Num.pi * 2)
            var a = Random.rand() * Num.pi * 2
            Surface.draw_angle(IMAGE_CASING, shoot_pos + v, a)
        Surface.reset_target()

        Game.stats.add_shot()

        _cooldown = stats.fire_rate
    }

    render() {
        var cam_adjusted_pos = _pos - CAMERA
        Surface.draw_angle(_sprite, cam_adjusted_pos, _angle)
    }

    render_ui() {
        if (_lvl < _upgrades.count - 1) {
            var kills_left = _upgrade_cost - _kills
            Draw.text(4, 4, "Next upgrade: %(kills_left) kill%(kills_left > 1 ? "s" : "")", Color.WHITE)
        }
    }
}
class Car is Entity {
    max_hp { 5 }

    engine_power { 480 }
    engine_torque { 0.02 }
    friction { 0.025 }
    angular_speed { 4.8 }
    angular_torque { 0.05 }

    turret_offset { Vector.new(-12, 0) }

    pos { _pos }
    vel { _vel }
    angle { _angle }

    construct new(pos) {
        _pos = pos
        _vel = Vector.ZERO
        _angle = Num.pi / 2
        _angvel = 0
        _sprite = Surface.new_from_png("car.png")

        var bar_width = 120
        _hp_bar = ProgressBar.new(COLOR_HP, 0, max_hp, max_hp, bar_width, 8)
        _tp_bar = ProgressBar.new(COLOR_CYAN, Color.WHITE, 0, 100, 100, bar_width, 6)

        _turret = Turret.new(pos)
    }

    hurt(damage) {
        Game.hide_title()
        Game.spawn(Flash.new(COLOR_HP))
        Game.shake_camera(2.5)
        _hp_bar.value = _hp_bar.value - damage

        if (_hp_bar.is_empty) {
            kill()
        }
    }

    tick(dt) {
        if (is_dead) {
            tick_dead(dt)
            return
        }

        update_camera()
        _turret.tick(dt)

        _current_speed = _vel.length
        _facing = Vector.RIGHT.rotated(_angle)
        _car_angle_diff = _vel.angle_to(_facing).abs

        var up = Input.is_key_held(KEY_UP) || Input.is_key_held(KEY_UP_ALT) || Input.is_key_held(KEY_UP_FR)

        var down = Input.is_key_held(KEY_DOWN) || Input.is_key_held(KEY_DOWN_ALT)

        var left = Input.is_key_held(KEY_LEFT) || Input.is_key_held(KEY_LEFT_ALT) || Input.is_key_held(KEY_LEFT_FR)

        var right = Input.is_key_held(KEY_RIGHT) || Input.is_key_held(KEY_RIGHT_ALT)

        if (up) {
            Game.hide_title()
            var target_vel = Vector.new(engine_power, 0).rotated(_angle)
            _vel = Math.lerp(_vel, target_vel, engine_torque)
        } else {
            _vel = Math.lerp(_vel, Vector.ZERO, friction)
        }

        if (left && _current_speed > 1) { // turning
            _angvel = Math.lerp(_angvel, angular_speed, angular_torque)
        } else if (right && _current_speed > 1) {
            _angvel = Math.lerp(_angvel, -angular_speed, angular_torque)
        } else {
            _angvel = Math.lerp(_angvel, 0, angular_torque)
        }

        _angle = _angle + _angvel * dt
        _pos = (_pos + _vel * dt).clamped(Vector.ZERO, MAP_BOUNDS)
        _turret.pos = _pos + turret_offset.rotated(_angle)

        update_tp_charge(dt)

        // hack for windows :)
        if (Input.get_mouse_button() > 1) {
            Game.hide_title()
            teleport()
        }
    }

    tick_dead(dt) {
        if (FRAME % 8 == 0) {
            var v = Vector.RIGHT.rotated(Random.rand() * Num.pi * 2) * Random.rand() * 30
            Game.spawn(Explosion.new(_pos + v))
        }

        if (Input.is_key_pressed(KEY_RESTART)) {
            Game.queue_restart()
        }
    }

    update_camera() {
        var target_cam_pos = _pos - Vector.new(WIDTH/2, HEIGHT/2)
        var cam_offset = Vector.RIGHT.rotated(_angle) * CAMERA_FORWARD_OFFSET
        CAMERA = Math.lerp(CAMERA, target_cam_pos + cam_offset, CAMERA_SMOOTHING)
    }

    update_tp_charge(dt) {
        var increase = Math.map(
            (_current_speed + 1) * _car_angle_diff,
            0, Num.pi * engine_power,
            0, 50
        )

        _tp_bar.value = _tp_bar.value + increase * dt
    }

    fill_tp() {
        _tp_bar.fill()
    }

    teleport() {
        if (_tp_bar.is_full) {
            _tp_bar.empty()

            var start = _pos
            var end = CAMERA + Input.mouse_pos()

            SOUND_TP.play()
            Game.spawn(Flash.new(COLOR_CYAN))
            Game.spawn(TeleportStreak.new(start, end))

            Game.kill_enemies_on_line(start, end, 32)

            _pos = end
        }
    }

    killed_enemy() {
        _turret.killed_enemy()
    }

    render() {
        var cam_adjusted_pos = _pos - CAMERA
        Surface.draw_angle(_sprite, cam_adjusted_pos, _angle)
        _turret.render()

        // draw tire streaks
        if (_current_speed > 1) {
            var streak_color = Color.BLACK
            streak_color.a = Math.map(
                _car_angle_diff,
                0, Num.pi,
                0, 128
            ) * (_current_speed / engine_power / 2 + 0.5)
            var size = 3 + Random.rand()

            var offset_1 = Vector.new(Random.rand(), Random.rand())
            var offset_2 = Vector.new(Random.rand(), Random.rand())

            Surface.set_target(GROUND_SURFACE)
                var x = 22
                var y = 6
                Draw.circle(
                    _pos + Vector.new(-x, y).rotated(_angle) + offset_1,
                    size, streak_color, true
                )
                Draw.circle(
                    _pos + Vector.new(-x, -y).rotated(_angle) + offset_2,
                    size, streak_color, true
                )
            Surface.reset_target()
        }
    }

    render_ui() {
        if (is_dead) {
            Draw.rectangle(WIDTH / 2 - 100, HEIGHT / 2 - 40, 200, 80, Color.new(0, 0, 0, 160), true)
            Draw.text(WIDTH / 2 - 28, HEIGHT / 2 - 14, "YOU DIED", COLOR_HP)

            if (FRAME % 60 < 40) {
                Draw.text(WIDTH / 2 - 37, HEIGHT / 2 + 4, "Press SPACE", Color.WHITE)
            }

            return
        }

        _hp_bar.draw_centered(HEIGHT - 10)
        _tp_bar.draw_centered(HEIGHT - 18)
        if (_tp_bar.is_full) {
            Draw.text(WIDTH/2 - 65, HEIGHT - 32, "TELEPORTATION READY", Color.WHITE)
        }

        _turret.render_ui()
    }
}
var ENEMY_SPRITE = Surface.new_from_png("drone.png")

class Enemy is Entity {
    speed { 100 }
    rotate_speed { Num.pi }
    radius { 8 }
    explode_range { 26 }

    pos { _pos }

    construct new(pos) {
        _pos = pos
        _vel = Vector.new(speed, 0).rotated(Random.rand() * Num.pi)
        _angle = 0
    }

    kill() {
        super.kill()
        SOUND_EXPLOSION.play(1.0, 0.7 + (Random.irange(1, 3) / 3), 1.0)
        Game.spawn(Explosion.new(_pos))
        Game.shake_camera()
    }

    tick(dt) {
        if (CAR.pos.distance_to(_pos) < explode_range) {
            kill()
            CAR.hurt(1)
        }

        _pos = _pos + _vel * dt
        if (_pos.x < radius) {
            _pos.x = radius
            _vel.x = -_vel.x
        }
        if (_pos.x > MAP_BOUNDS.x - radius) {
            _pos.x = MAP_BOUNDS.x - radius
            _vel.x = -_vel.x
        }
        if (_pos.y < radius) {
            _pos.y = radius
            _vel.y = -_vel.y
        }
        if (_pos.y > MAP_BOUNDS.y - radius) {
            _pos.y = MAP_BOUNDS.y - radius
            _vel.y = -_vel.y
        }

        _angle = _angle + rotate_speed * dt
    }

    render() {
        var cam_adjusted_pos = _pos - CAMERA
        Surface.draw_angle(ENEMY_SPRITE, cam_adjusted_pos, _angle)
    }
}

var ENEMY_MOVE_SPRITE = Surface.new_from_png("drone_f.png")

class EnemyMove is Entity {
    speed { 80 }
    rotate_speed { Num.pi * 1.5 }
    radius { 8 }
    explode_range { 26 }

    pos { _pos }

    construct new(pos) {
        _pos = pos
        _vel = Vector.ZERO
        _angle = 0
    }

    kill() {
        super.kill()
        SOUND_EXPLOSION.play(1.0, 0.7 + (Random.irange(1, 3) / 3), 1.0)
        Game.spawn(Explosion.new(_pos))
        Game.shake_camera()
    }

    tick(dt) {
        if (CAR.pos.distance_to(_pos) < explode_range) {
            kill()
            CAR.hurt(1)
        }

        // Go to the player
        var target_vel = (CAR.pos - _pos).normalized * speed
        _vel = Math.lerp(_vel, target_vel, 0.1)

        _pos = _pos + _vel * dt

        _angle = _angle + rotate_speed * dt
    }

    render() {
        var cam_adjusted_pos = _pos - CAMERA
        Surface.draw_angle(ENEMY_MOVE_SPRITE, cam_adjusted_pos, _angle)
    }
}

var NUKE_SPRITE = Surface.new_from_png("nuke.png")
var TARGET_SPRITE = Surface.new_from_png("target.png")

class Nuke is Entity {
    drop_height { HEIGHT * 1.5 }
    drop_speed { 400 }
    explode_range { 32 }

    construct new(target_pos) {
        _target = target_pos
        _pos = target_pos + Vector.new(0, -drop_height)
        SOUND_NUKE_INCOMING.play()
    }

    tick(dt) {
        _pos = _pos + Vector.DOWN * drop_speed * dt

        if (_pos.y >= _target.y) {
            kill()
            Game.spawn(Explosion.new(_target))
            Game.shake_camera(2)
            SOUND_NUKE.play()

            if (CAR.pos.distance_to(_target) < explode_range) {
                CAR.hurt(3)
            }
        }
    }

    render() {
        if (FRAME % 20 < 10) {
            Surface.draw_centered(TARGET_SPRITE, _target - CAMERA, 1.0)
        }

        Surface.draw_centered(NUKE_SPRITE, _pos - CAMERA, 1.0)
    }
}
class GameStats {
    construct new() {
        _kills = 0
        _tpkills = 0
        _shots = 0
        _time = 0

        _color = Color.new(180, 180, 180)
    }

    tick(dt) {
        _time = _time + dt
    }

    add_kill() {
        _kills = _kills + 1
    }

    add_tpkill() {
        _tpkills = _tpkills + 1
    }

    add_shot() {
        _shots = _shots + 1
    }

    render() {
        var x = WIDTH/2 - 95
        var y = HEIGHT/2 + 45
        var spacing = 12
        Draw.text(x, y, "Kills: %(_kills) shot, %(_tpkills) telefragged", _color)
        Draw.text(x, y + spacing, "Shots: %(_shots)", _color)
        Draw.text(x, y + spacing*2, "Accuracy: %((_kills/_shots * 100).round)\%", _color)
        var m = (_time / 60).ceil
        var s = _time.ceil % 60
        Draw.text(x, y + spacing*3, "Survived for: %(m)m%(s)s", _color)
    }
}

class Game {
    static title { "Quantum Drift" }

    // initial time between each enemy spawn (in seconds)
    static wave_time_start { 8.0 }
    // minimum time between each enemy spawn (in seconds)
    static wave_time_cap { 1.0 }
    // how much the wave time goes down each wave
    static wave_time_step { 1.0 }

    // wave_time at which to start dropping nukes
    static nuke_wave_start { 2.0 }
    // interval between nukes (in seconds)
    static nuke_interval { 10.0 }

    static stats { __stats }

    static init_title() {
        TITLE_SURFACE = Surface.new(106, 9)
        Surface.set_target(TITLE_SURFACE)
            Draw.text(0, 0, "QUANTUM DORIFTO", Color.WHITE)
        Surface.reset_target()
    }

    static init_ground() {
        GROUND_SURFACE = Surface.new(MAP_BOUNDS.x, MAP_BOUNDS.y)
        Surface.set_target(GROUND_SURFACE)
            // Some noise
            for (x in 1...MAP_BOUNDS.x) {
                for (y in 1...MAP_BOUNDS.y) {
                    var color_val = GROUND_COLOR + Random.irange(-GROUND_NOISE, GROUND_NOISE)
                    Draw.put_pixel(x, y, color_val, color_val, color_val)
                }
            }
            Draw.rectangle(
                Vector.new(1, 1), Vector.new(MAP_BOUNDS.x - 2, MAP_BOUNDS.y - 2),
                Color.new(180), false)
            Draw.rectangle(Vector.ZERO, MAP_BOUNDS, Color.WHITE, false)
            Surface.draw_centered(TUTORIAL, MAP_BOUNDS/2, 0.3)
        Surface.reset_target()
    }

    static init(args) {
        Engine.init(WIDTH, HEIGHT, title)
        Random.seed(System.clock)

        init_title()
        restart()
    }

    static restart() {
        __stats = GameStats.new()

        __show_timer = true
        __should_restart = false
        init_ground()

        __entities = []
        __enemies = []

        CAR = Car.new(MAP_BOUNDS / 2)
        CAMERA = CAR.pos - Vector.new(WIDTH/2, HEIGHT/2)

        __wave_time = wave_time_start
        __wave_time_left = __wave_time
        __nuke_timer = nuke_interval

        __shake_timer = 0

        System.gc()
    }

    static queue_restart() {
        __should_restart = true
    }

    static spawn(e) {
        __entities.add(e)
    }

    static spawn_enemy(e) {
        __enemies.add(e)
    }

    static kill_enemy_at(pos, radius) {
        for (e in __enemies) {
            if (e.pos.distance_to(pos) <= radius) {
                e.kill()

                Game.stats.add_kill()
                CAR.fill_tp()
                CAR.killed_enemy()
                return true
            }
        }

        return false
    }

    static kill_enemies_on_line(start, end, radius) {
        for (e in __enemies) {
            if (e.pos.distance_to_line(start, end) <= radius) {
                e.kill()
                CAR.killed_enemy()

                __stats.add_tpkill()
            }
        }
    }

    static get_position_outside_camera() {
        var pos = Vector.new(
            Random.irange(0, MAP_BOUNDS.x),
            Random.irange(0, MAP_BOUNDS.y)
        )

        while (pos.x >= CAMERA.x && pos.x <= CAMERA.x + WIDTH &&
               pos.y >= CAMERA.y && pos.y <= CAMERA.y + HEIGHT) {
            pos = Vector.new(
                Random.irange(0, MAP_BOUNDS.x),
                Random.irange(0, MAP_BOUNDS.y)
            )
        }

        return pos
    }

    static tick_wave(dt) {
        __wave_time_left = __wave_time_left - dt

        if (__wave_time_left <= 0) {
            __wave_time = (__wave_time - wave_time_step).max(wave_time_cap)
            __wave_time_left = __wave_time

            spawn_enemy(Enemy.new(get_position_outside_camera()))

            // chance of a second enemy that seeks player, based on wave time
            // do not spawn seeking enemies when the title is visible
            if (!__show_timer && Random.irange(0, __wave_time) == 0) {
                spawn_enemy(EnemyMove.new(get_position_outside_camera()))
            }
        }

        if (__wave_time <= nuke_wave_start) {
            __nuke_timer = __nuke_timer - dt

            if (__nuke_timer <= 0) {
                __nuke_timer = nuke_interval
                spawn(Nuke.new(CAR.pos))
            }
        }
    }

    static tick(dt) {
        tick_wave(dt)

        CAR.tick(dt)

        tick_entities(__entities, dt)
        tick_entities(__enemies, dt)

        if (__shake_timer > 0) {
            __shake_timer = __shake_timer - dt
            tick_shake()
        }

        // RENDERING -----------------------------------------------------------
        Draw.clear(Color.BLACK)
        Surface.draw(GROUND_SURFACE, -CAMERA.x, -CAMERA.y, 1.0)

        CAR.render()
        for (e in __enemies) {
            e.render()
        }
        for (e in __entities) {
            e.render()
        }

        // draw title
        if (__show_timer) {
            draw_title()
        } else {
            CAR.render_ui()

            if (CAR.is_dead) {
                __stats.render()
            } else {
                __stats.tick(dt)
            }
        }

        if (__should_restart) {
            restart()
        }

        FRAME = FRAME + 1
    }

    static draw_title() {
        // force camera to center
        CAMERA.x = MAP_BOUNDS.x/2 - WIDTH/2
        CAMERA.y = MAP_BOUNDS.y/2 - HEIGHT/2
        var spacing = 2
        for (i in 4..0) {
            Surface.draw_centered(
                TITLE_SURFACE,
                Vector.new(WIDTH/2 + i * spacing, HEIGHT/2 - 100 + i * spacing),
                1/(i+1)
            )
        }
    }

    static hide_title() {
        __show_timer = false
    }

    static tick_entities(list, dt) {
        var i = list.count - 1
        while (i >= 0) {
            var e = list[i]
            e.tick(dt)

            if (e.is_dead) {
                list.removeAt(i)
            }

            i = i - 1
        }
    }

    static tick_shake() {
        var amp = Math.map(__shake_timer, SCREENSHAKE_TIME, 0, SCREENSHAKE_STRENGTH, 0)
        var v = Vector.RIGHT.rotated(Random.rand() * Num.pi * 2) * amp
        CAMERA = CAMERA + v
    }

    static shake_camera() {
        shake_camera(1)
    }

    static shake_camera(time) {
        var new_time = time * SCREENSHAKE_TIME
        if (new_time > __shake_timer) {
            __shake_timer = new_time
        }
    }
}
