/*
** Strip comments from a wren file
** Remove spaces at the beginning of a line
*/

class Game {
    static init(args) {
        if (args.count < 3) {
            System.print("Usage: compact <file> <output>")
            return 1
        }

        var input = args[1]
        var output = args[2]
        var file = FileIO.open(input, "r")
        var out = FileIO.open(output, "w")

        System.print("Compacting " + input + " to " + output + "...")
        var current_line = ""
        for (ch in file.read()) {
            if (ch == "\n") {
                // Remove bloat
                var line = current_line.trim()
                if (!(line.count == 0 || line.startsWith("//"))) {
                    out.write(line + "\n")
                }
                // Reset
                current_line = ""
            } else {
                current_line = current_line + ch
            }
        }

        file.close()
        out.close()

        return 0
    }
}
