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
