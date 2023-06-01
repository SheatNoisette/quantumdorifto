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
