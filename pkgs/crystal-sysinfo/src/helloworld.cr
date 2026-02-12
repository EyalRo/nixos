require "gtk4"

class SystemInfo
  def self.get_cpu_info
    cpu_model = File.read("/proc/cpuinfo").lines.find(&.starts_with?("model name"))
    cpu_model = cpu_model.split(":")[1].strip if cpu_model
    cpu_cores = File.read("/proc/cpuinfo").lines.count(&.starts_with?("processor"))
    "#{cpu_model} (#{cpu_cores} cores)"
  end

  def self.get_memory_info
    mem_info = File.read("/proc/meminfo")
    total_mem = mem_info.lines.find(&.starts_with?("MemTotal"))
    if total_mem
      total_kb = total_mem.split[1].to_i
      "#{(total_kb / 1024 / 1024).round(2)} GB"
    else
      "Unknown"
    end
  end

  def self.get_os_info
    os_release = File.exists?("/etc/os-release") ? File.read("/etc/os-release") : ""
    pretty_name = os_release.lines.find(&.starts_with?("PRETTY_NAME"))
    pretty_name = pretty_name.split("=")[1].strip.gsub("\"", "") if pretty_name
    pretty_name || "Unknown"
  end

  def self.get_kernel_info
    `uname -r`.strip
  end

  def self.get_uptime
    uptime_seconds = File.read("/proc/uptime").split[0].to_f
    days = (uptime_seconds / 86400).to_i
    hours = ((uptime_seconds % 86400) / 3600).to_i
    minutes = ((uptime_seconds % 3600) / 60).to_i
    "#{days}d #{hours}h #{minutes}m"
  end

  def self.get_all_info
    {
      "CPU" => get_cpu_info,
      "Memory" => get_memory_info,
      "OS" => get_os_info,
      "Kernel" => get_kernel_info,
      "Uptime" => get_uptime
    }
  end
end

app = Gtk::Application.new("sysinfo.example.com", Gio::ApplicationFlags::None)

app.activate_signal.connect do
  window = Gtk::ApplicationWindow.new(app)
  window.title = "System Information"
  window.set_default_size(500, 400)

  box = Gtk::Box.new(:vertical, 10)
  box.margin_top = 20
  box.margin_bottom = 20
  box.margin_start = 20
  box.margin_end = 20

  title_label = Gtk::Label.new("")
  title_label.markup = "<b><big>System Information</big></b>"
  title_label.margin_bottom = 20
  box.append(title_label)

  refresh_button = Gtk::Button.new_with_label("Refresh")
  refresh_button.margin_bottom = 20

  info_grid = Gtk::Grid.new()
  info_grid.column_spacing = 20
  info_grid.row_spacing = 10

  info_labels = {} of String => Gtk::Label

  SystemInfo.get_all_info.each_with_index do |(key, value), index|
    key_label = Gtk::Label.new("")
    key_label.markup = "<b>#{key}:</b>"
    key_label.halign = Gtk::Align::Start
    key_label.xalign = 0

    value_label = Gtk::Label.new(value)
    value_label.halign = Gtk::Align::Start
    value_label.xalign = 0
    value_label.selectable = true
    info_labels[key] = value_label

    info_grid.attach(key_label, 0, index, 1, 1)
    info_grid.attach(value_label, 1, index, 1, 1)
  end

  refresh_button.clicked_signal.connect do
    SystemInfo.get_all_info.each do |key, value|
      if label = info_labels[key]?
        label.label = value
      end
    end
  end

  box.append(refresh_button)
  box.append(info_grid)
  window.child = box
  window.present
end

exit(app.run)