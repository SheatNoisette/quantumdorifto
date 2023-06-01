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
