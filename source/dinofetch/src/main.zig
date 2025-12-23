const std = @import("std");

pub fn main() !void {
    const stdout = std.fs.File.stdout();
    const columns = getColumns();
    const rows: usize = 6;

    // 1x1 dark gray pixel in raw RGB (0x2b, 0x2b, 0x2b) -> base64 "Kysr".
    const kitty_pixel = "Kysr";

    // Kitty graphics protocol: render a tiny image block as a visual accent.
    var header_buf: [128]u8 = undefined;
    const header = try std.fmt.bufPrint(
        &header_buf,
        "\x1b_Gf=24,a=T,s=1,v=1,c={d},r={d};",
        .{ columns, rows },
    );
    try stdout.writeAll(header);
    try stdout.writeAll(kitty_pixel);
    try stdout.writeAll("\x1b\\\n");

    // Nerd Font glyph plus underlined title.
    try stdout.writeAll("\x1b[4m DinOS\x1b[0m\n");
}

fn getColumns() usize {
    const env = std.posix.getenv("COLUMNS") orelse return 80;
    const parsed = std.fmt.parseInt(usize, std.mem.sliceTo(env, 0), 10) catch return 80;
    if (parsed == 0) return 80;
    return parsed;
}
