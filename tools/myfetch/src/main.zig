const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const kitty_png_1x1 =
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGD4DwAB"
        "BAEAfbE5WQAAAABJRU5ErkJggg==";

    // Kitty graphics protocol: render a tiny image block as a visual accent.
    try stdout.writeAll("\x1b_Gf=100,a=T,s=1,v=1;");
    try stdout.writeAll(kitty_png_1x1);
    try stdout.writeAll("\x1b\\\n");

    // Nerd Font glyph plus underlined title.
    try stdout.writeAll("\x1b[4m DinOS\x1b[0m\n");
}
