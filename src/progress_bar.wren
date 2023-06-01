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
