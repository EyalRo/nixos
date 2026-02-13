const std = @import("std");
const c = @cImport({
    @cInclude("sys/statvfs.h");
});

pub fn main() !void {
    const stdout = std.fs.File.stdout();
    const term = getTerminalSize();
    const columns = if (term) |t| t.columns else getColumns();
    const rows = if (term) |t| t.rows else getRows();
    const allocator = std.heap.page_allocator;

    const data = try collectSystemData(allocator);
    defer data.deinit(allocator);

    const png = try buildInfoPng(allocator, data, 320, 160);
    defer allocator.free(png);

    try displayPngKitty(stdout, png, columns, rows);
}

// Data collection
const SystemData = struct {
    cpu_model: []u8,
    mem_total_bytes: u64,
    mem_used_bytes: u64,
    disk_total_bytes: u64,
    disk_used_bytes: u64,

    fn deinit(self: *const SystemData, allocator: std.mem.Allocator) void {
        allocator.free(self.cpu_model);
    }
};

fn collectSystemData(allocator: std.mem.Allocator) !SystemData {
    const cpu_model = try readCpuModel(allocator);
    const mem = try readMemInfo();
    const disk = try readDiskInfo();

    return .{
        .cpu_model = cpu_model,
        .mem_total_bytes = mem.total_bytes,
        .mem_used_bytes = mem.total_bytes - mem.available_bytes,
        .disk_total_bytes = disk.total_bytes,
        .disk_used_bytes = disk.total_bytes - disk.available_bytes,
    };
}

fn readCpuModel(allocator: std.mem.Allocator) ![]u8 {
    var file = try std.fs.openFileAbsolute("/proc/cpuinfo", .{});
    defer file.close();
    const contents = try file.readToEndAlloc(allocator, 1024 * 64);
    defer allocator.free(contents);

    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "model name")) {
            const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
            const raw = std.mem.trim(u8, line[colon + 1 ..], " \t");
            return try sanitizeText(allocator, raw, 48);
        }
    }

    return try allocator.dupe(u8, "UNKNOWN CPU");
}

const MemInfo = struct {
    total_bytes: u64,
    available_bytes: u64,
};

fn readMemInfo() !MemInfo {
    var file = try std.fs.openFileAbsolute("/proc/meminfo", .{});
    defer file.close();

    var buf: [4096]u8 = undefined;
    const read_len = try file.readAll(&buf);
    const contents = buf[0..read_len];

    var total_kb: u64 = 0;
    var available_kb: u64 = 0;

    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "MemTotal:")) {
            total_kb = parseMeminfoLine(line) orelse total_kb;
        } else if (std.mem.startsWith(u8, line, "MemAvailable:")) {
            available_kb = parseMeminfoLine(line) orelse available_kb;
        }
    }

    if (total_kb == 0) return error.MemInfoUnavailable;
    if (available_kb == 0) return error.MemInfoUnavailable;

    return .{
        .total_bytes = total_kb * 1024,
        .available_bytes = available_kb * 1024,
    };
}

fn parseMeminfoLine(line: []const u8) ?u64 {
    const colon = std.mem.indexOfScalar(u8, line, ':') orelse return null;
    var rest = std.mem.trim(u8, line[colon + 1 ..], " \t");
    const space = std.mem.indexOfScalar(u8, rest, ' ') orelse rest.len;
    rest = rest[0..space];
    return std.fmt.parseInt(u64, rest, 10) catch null;
}

const DiskInfo = struct {
    total_bytes: u64,
    available_bytes: u64,
};

fn readDiskInfo() !DiskInfo {
    var stat: c.struct_statvfs = undefined;
    if (c.statvfs("/", &stat) != 0) return error.StatVfsFailed;

    const block_size = @as(u64, stat.f_frsize);
    return .{
        .total_bytes = block_size * @as(u64, stat.f_blocks),
        .available_bytes = block_size * @as(u64, stat.f_bavail),
    };
}

fn sanitizeText(allocator: std.mem.Allocator, input: []const u8, max_len: usize) ![]u8 {
    var out = try allocator.alloc(u8, max_len);
    var out_len: usize = 0;

    for (input) |byte| {
        if (out_len >= max_len) break;
        const upper = if (byte >= 'a' and byte <= 'z') byte - 32 else byte;
        if ((upper >= 'A' and upper <= 'Z') or (upper >= '0' and upper <= '9') or upper == ' ') {
            out[out_len] = upper;
            out_len += 1;
        }
    }

    if (out_len == 0) {
        allocator.free(out);
        return allocator.dupe(u8, "UNKNOWN CPU");
    }

    return allocator.realloc(out, out_len);
}

fn formatBytes(allocator: std.mem.Allocator, bytes: u64) ![]u8 {
    const gb: u64 = 1024 * 1024 * 1024;
    const mb: u64 = 1024 * 1024;

    if (bytes >= gb) {
        const whole = bytes / gb;
        const frac = (bytes % gb) * 10 / gb;
        return std.fmt.allocPrint(allocator, "{d}.{d}G", .{ whole, frac });
    }

    const whole_mb = bytes / mb;
    return std.fmt.allocPrint(allocator, "{d}M", .{whole_mb});
}

// PNG generation
fn buildInfoPng(allocator: std.mem.Allocator, data: SystemData, width: usize, height: usize) ![]u8 {
    const pixel_len = width * height * 3;
    const pixels = try allocator.alloc(u8, pixel_len);
    defer allocator.free(pixels);

    @memset(pixels, 0x2b);

    const cpu_line = try std.fmt.allocPrint(allocator, "CPU: {s}", .{data.cpu_model});
    defer allocator.free(cpu_line);
    const mem_used = try formatBytes(allocator, data.mem_used_bytes);
    defer allocator.free(mem_used);
    const mem_total = try formatBytes(allocator, data.mem_total_bytes);
    defer allocator.free(mem_total);
    const mem_line = try std.fmt.allocPrint(allocator, "RAM: {s}/{s}", .{ mem_used, mem_total });
    defer allocator.free(mem_line);
    const disk_used = try formatBytes(allocator, data.disk_used_bytes);
    defer allocator.free(disk_used);
    const disk_total = try formatBytes(allocator, data.disk_total_bytes);
    defer allocator.free(disk_total);
    const disk_line = try std.fmt.allocPrint(allocator, "DISK: {s}/{s}", .{ disk_used, disk_total });
    defer allocator.free(disk_line);

    const lines = [_][]const u8{
        "DINOFETCH",
        cpu_line,
        mem_line,
        disk_line,
    };

    const glyph_w: usize = 5;
    const glyph_h: usize = 7;
    const scale: usize = 2;
    const spacing: usize = 1;
    const line_height = glyph_h * scale + 6;
    var y: usize = 12;

    for (lines) |line| {
        const max_chars = (width - 12) / (glyph_w * scale + spacing);
        const clipped = clipText(line, max_chars);
        drawText(pixels, width, height, 10, y, clipped, scale, .{ 0xe6, 0xe6, 0xe6 });
        y += line_height;
    }

    return try encodePng(allocator, pixels, width, height);
}

fn clipText(line: []const u8, max_chars: usize) []const u8 {
    if (line.len <= max_chars) return line;
    if (max_chars <= 3) return line[0..max_chars];
    return line[0 .. max_chars - 3];
}

fn drawText(pixels: []u8, width: usize, height: usize, x: usize, y: usize, text: []const u8, scale: usize, color: [3]u8) void {
    var cursor_x = x;
    for (text) |byte| {
        const glyph = glyphFor(byte);
        drawGlyph(pixels, width, height, cursor_x, y, glyph, scale, color);
        cursor_x += 5 * scale + 1;
    }
}

fn drawGlyph(pixels: []u8, width: usize, height: usize, x: usize, y: usize, glyph: [7]u8, scale: usize, color: [3]u8) void {
    var row: usize = 0;
    while (row < 7) : (row += 1) {
        var col: usize = 0;
        while (col < 5) : (col += 1) {
            const shift: u3 = @intCast(4 - col);
            const mask: u8 = @as(u8, 1) << shift;
            if ((glyph[row] & mask) != 0) {
                fillScaledPixel(pixels, width, height, x + col * scale, y + row * scale, scale, color);
            }
        }
    }
}

fn fillScaledPixel(pixels: []u8, width: usize, height: usize, x: usize, y: usize, scale: usize, color: [3]u8) void {
    var dy: usize = 0;
    while (dy < scale) : (dy += 1) {
        const py = y + dy;
        if (py >= height) continue;
        var dx: usize = 0;
        while (dx < scale) : (dx += 1) {
            const px = x + dx;
            if (px >= width) continue;
            const idx = (py * width + px) * 3;
            pixels[idx] = color[0];
            pixels[idx + 1] = color[1];
            pixels[idx + 2] = color[2];
        }
    }
}

fn glyphFor(byte: u8) [7]u8 {
    const upper = if (byte >= 'a' and byte <= 'z') byte - 32 else byte;
    return switch (upper) {
        'A' => .{ 0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001 },
        'B' => .{ 0b11110, 0b10001, 0b10001, 0b11110, 0b10001, 0b10001, 0b11110 },
        'C' => .{ 0b01110, 0b10001, 0b10000, 0b10000, 0b10000, 0b10001, 0b01110 },
        'D' => .{ 0b11110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b11110 },
        'E' => .{ 0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b11111 },
        'F' => .{ 0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b10000 },
        'G' => .{ 0b01110, 0b10001, 0b10000, 0b10111, 0b10001, 0b10001, 0b01110 },
        'H' => .{ 0b10001, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001 },
        'I' => .{ 0b01110, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110 },
        'J' => .{ 0b00111, 0b00010, 0b00010, 0b00010, 0b10010, 0b10010, 0b01100 },
        'K' => .{ 0b10001, 0b10010, 0b10100, 0b11000, 0b10100, 0b10010, 0b10001 },
        'L' => .{ 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11111 },
        'M' => .{ 0b10001, 0b11011, 0b10101, 0b10101, 0b10001, 0b10001, 0b10001 },
        'N' => .{ 0b10001, 0b11001, 0b10101, 0b10011, 0b10001, 0b10001, 0b10001 },
        'O' => .{ 0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110 },
        'P' => .{ 0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000 },
        'Q' => .{ 0b01110, 0b10001, 0b10001, 0b10001, 0b10101, 0b10010, 0b01101 },
        'R' => .{ 0b11110, 0b10001, 0b10001, 0b11110, 0b10100, 0b10010, 0b10001 },
        'S' => .{ 0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110 },
        'T' => .{ 0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100 },
        'U' => .{ 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110 },
        'V' => .{ 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01010, 0b00100 },
        'W' => .{ 0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b10101, 0b01010 },
        'X' => .{ 0b10001, 0b10001, 0b01010, 0b00100, 0b01010, 0b10001, 0b10001 },
        'Y' => .{ 0b10001, 0b10001, 0b01010, 0b00100, 0b00100, 0b00100, 0b00100 },
        'Z' => .{ 0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0b11111 },
        '0' => .{ 0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110 },
        '1' => .{ 0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110 },
        '2' => .{ 0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111 },
        '3' => .{ 0b11110, 0b00001, 0b00001, 0b01110, 0b00001, 0b00001, 0b11110 },
        '4' => .{ 0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010 },
        '5' => .{ 0b11111, 0b10000, 0b11110, 0b00001, 0b00001, 0b10001, 0b01110 },
        '6' => .{ 0b00110, 0b01000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110 },
        '7' => .{ 0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000 },
        '8' => .{ 0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110 },
        '9' => .{ 0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00010, 0b01100 },
        ':' => .{ 0b00000, 0b00100, 0b00100, 0b00000, 0b00100, 0b00100, 0b00000 },
        '/' => .{ 0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0b00000, 0b00000 },
        '.' => .{ 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b01100, 0b01100 },
        '-' => .{ 0b00000, 0b00000, 0b00000, 0b11111, 0b00000, 0b00000, 0b00000 },
        ' ' => .{ 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000 },
        else => .{ 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000 },
    };
}

fn encodePng(allocator: std.mem.Allocator, pixels: []const u8, width: usize, height: usize) ![]u8 {
    const row_len = 1 + 3 * width;
    const raw_len = row_len * height;
    var raw = try allocator.alloc(u8, raw_len);
    defer allocator.free(raw);

    var idx: usize = 0;
    var y: usize = 0;
    while (y < height) : (y += 1) {
        raw[idx] = 0;
        idx += 1;
        const row_start = y * width * 3;
        @memcpy(raw[idx .. idx + width * 3], pixels[row_start .. row_start + width * 3]);
        idx += width * 3;
    }

    var zlib = try std.ArrayList(u8).initCapacity(allocator, 0);
    defer zlib.deinit(allocator);
    try zlib.append(allocator, 0x78);
    try zlib.append(allocator, 0x01);

    var offset: usize = 0;
    while (offset < raw_len) {
        const remaining = raw_len - offset;
        const block_len: u16 = @intCast(@min(remaining, 0xffff));
        const is_final = offset + block_len >= raw_len;
        const header: u8 = if (is_final) 0x01 else 0x00;
        try zlib.append(allocator, header);
        try zlib.append(allocator, @intCast(block_len & 0xff));
        try zlib.append(allocator, @intCast((block_len >> 8) & 0xff));
        const nlen: u16 = @intCast(0xffff - block_len);
        try zlib.append(allocator, @intCast(nlen & 0xff));
        try zlib.append(allocator, @intCast((nlen >> 8) & 0xff));
        try zlib.appendSlice(allocator, raw[offset .. offset + block_len]);
        offset += block_len;
    }
    const adler = adler32(raw);
    var adler_buf: [4]u8 = undefined;
    std.mem.writeInt(u32, adler_buf[0..], adler, .big);
    try zlib.appendSlice(allocator, adler_buf[0..]);

    var png = try std.ArrayList(u8).initCapacity(allocator, 0);
    defer png.deinit(allocator);
    try png.appendSlice(allocator, "\x89PNG\r\n\x1a\n");

    var ihdr: [13]u8 = undefined;
    std.mem.writeInt(u32, ihdr[0..4], @intCast(width), .big);
    std.mem.writeInt(u32, ihdr[4..8], @intCast(height), .big);
    ihdr[8] = 8;
    ihdr[9] = 2;
    ihdr[10] = 0;
    ihdr[11] = 0;
    ihdr[12] = 0;
    try writeChunk(allocator, &png, "IHDR", &ihdr);
    try writeChunk(allocator, &png, "IDAT", zlib.items);
    try writeChunk(allocator, &png, "IEND", "");

    return try png.toOwnedSlice(allocator);
}

fn writeChunk(allocator: std.mem.Allocator, png: *std.ArrayList(u8), chunk_type: []const u8, data: []const u8) !void {
    var len_buf: [4]u8 = undefined;
    std.mem.writeInt(u32, len_buf[0..], @intCast(data.len), .big);
    try png.appendSlice(allocator, len_buf[0..]);
    try png.appendSlice(allocator, chunk_type);
    try png.appendSlice(allocator, data);

    var crc = Crc32.init();
    crc.update(chunk_type);
    crc.update(data);
    var crc_buf: [4]u8 = undefined;
    std.mem.writeInt(u32, crc_buf[0..], crc.final(), .big);
    try png.appendSlice(allocator, crc_buf[0..]);
}

const Crc32 = struct {
    value: u32,

    fn init() Crc32 {
        return .{ .value = 0xffffffff };
    }

    fn update(self: *Crc32, data: []const u8) void {
        for (data) |byte| {
            var crc_byte: u32 = (self.value ^ @as(u32, byte)) & 0xff;
            var k: u8 = 0;
            while (k < 8) : (k += 1) {
                if ((crc_byte & 1) == 1) {
                    crc_byte = 0xedb88320 ^ (crc_byte >> 1);
                } else {
                    crc_byte >>= 1;
                }
            }
            self.value = (self.value >> 8) ^ crc_byte;
        }
    }

    fn final(self: *Crc32) u32 {
        return self.value ^ 0xffffffff;
    }
};

fn adler32(data: []const u8) u32 {
    var a: u32 = 1;
    var b: u32 = 0;
    for (data) |byte| {
        a = (a + byte) % 65521;
        b = (b + a) % 65521;
    }
    return (b << 16) | a;
}

// Display
fn displayPngKitty(stdout: std.fs.File, png: []const u8, columns: usize, rows: usize) !void {
    const b64_len = std.base64.standard.Encoder.calcSize(png.len);
    const allocator = std.heap.page_allocator;
    const b64_buf = try allocator.alloc(u8, b64_len);
    defer allocator.free(b64_buf);
    const b64_png = std.base64.standard.Encoder.encode(b64_buf, png);

    try stdout.writeAll("\x1b7\x1b[H");
    var header_buf: [128]u8 = undefined;
    const header = try std.fmt.bufPrint(
        &header_buf,
        "\x1b_Gf=100,a=T,q=2,c={d},r={d},z=-1;",
        .{ columns, rows },
    );
    try stdout.writeAll(header);
    try stdout.writeAll(b64_png);
    try stdout.writeAll("\x1b\\");
    try stdout.writeAll("\x1b8");
}

fn getColumns() usize {
    const env = std.posix.getenv("COLUMNS") orelse return 80;
    const parsed = std.fmt.parseInt(usize, std.mem.sliceTo(env, 0), 10) catch return 80;
    if (parsed == 0) return 80;
    return parsed;
}

fn getRows() usize {
    const env = std.posix.getenv("LINES") orelse return 24;
    const parsed = std.fmt.parseInt(usize, std.mem.sliceTo(env, 0), 10) catch return 24;
    if (parsed == 0) return 24;
    return parsed;
}

fn getTerminalSize() ?struct { columns: usize, rows: usize } {
    if (!std.posix.isatty(std.posix.STDOUT_FILENO)) return null;
    var wsz: std.posix.winsize = undefined;
    const rc = std.os.linux.ioctl(std.posix.STDOUT_FILENO, std.os.linux.T.IOCGWINSZ, @intFromPtr(&wsz));
    if (std.os.linux.E.init(rc) != .SUCCESS) return null;
    if (wsz.col == 0 or wsz.row == 0) return null;
    return .{
        .columns = @intCast(wsz.col),
        .rows = @intCast(wsz.row),
    };
}
