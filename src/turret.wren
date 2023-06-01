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
