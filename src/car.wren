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
