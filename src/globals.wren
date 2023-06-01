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
