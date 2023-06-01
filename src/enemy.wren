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
